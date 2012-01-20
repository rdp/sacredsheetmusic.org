require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/admin/products_controller"

class Admin::ProductsController < Admin::BaseController
  class ContinueError < StandardError; end

  def list
   # we get here....
    @title = "All Product List"
    @products = Product.paginate(
    :order => "name ASC",
    :page => params[:page],
    :per_page => params[:per_page] || 100,
    :include => [:tags, :downloads] # just fer fun...
    )
  end

  def with_problems
    @products = Product.find(:all, :include => [:downloads, {:tags => [:parent, :children]}]).select{|p| p.find_problems.length > 0 }
    @title = 'all products with any problems listed'
    def @products.total_pages # fake it out :P
      1
    end
    render :action => :list
  end

  @@density = 125 # seems reasonable...

  # Saves product from new and edit.
  #
  #
  def self.density= to_this
   @@density = to_this
  end

  def fix_remove_piano_tag
    raise 'no id?' unless id = params[:id]
    product = Product.find(id)
    raise unless product
    init = product.tags.size
    product.tags = product.tags.reject{|t| t.name =~ /piano/i || t.name == "Instrumental"}
    now = product.tags.size
    product.clear_my_cache
    flash[:notice] = "removed #{init} -> #{now} tags"
    redirect_to :action => :edit, :id => params[:id]
  end

  # fix up any previously broken images from pdf's
  def regenerate
    raise 'no id?' unless id = params[:id]
    regenerate_internal params[:id]
    flash[:notice] = "regenerated images..."
    redirect_to :action => :edit, :id => params[:id]
  end

  def self.regenerate_all_images this_servers_name # needs to be self because we cannot run this in fcgi...
    products_with_images = Product.all(:include => :downloads).select{|p| p.downloads.detect{|dl| dl.name =~ /pdf$/i}}
    mini = products_with_images[0..2]
    out = []
    mini.each{|p|
      instance = self.new
      instance.params = {:id => p.id}
      def instance.flash() 
        @flash ||= {}
      end
      instance.regenerate_internal(p.id, this_servers_name)
      out << p.code
      puts p.code
    }
    out
  end

  def regenerate_internal id, this_servers_name_to_download_from = request.env['SERVER_NAME']
    product = Product.find(id)
    pdfs = product.downloads.select{|dl| dl.name =~ /pdf$/i }
    raise 'no pdfs' unless pdfs.present?
    logger.warn 'no images?' unless product.images.count > 0
    old_images = product.images[0..-1] # force it to load so we get an old snapshot of the original images
    pdfs.each{|dl|
      # save it with our old url, then delete the original...hmm...yeah
      # resets ids! params[:product] = {:tag_ids => []}
      params[:product] = {} # doesn't  reset tags...
      params[:download] = []
      params[:download_pdf_url] = "http://" + this_servers_name_to_download_from + dl.relative_path_to_web_server
      logger.info params[:download_pdf_url]
      save_internal false
      dl.destroy # scaway :)
     }
     old_images.each{|i| i.destroy unless i.name =~ /\.jpg$/i} # our one user contrib image is a jpeg :P
  end

  def save
    save_internal
  end

  def save_internal should_render = true
    # If we have ID param this isn't a new product
    if params[:id]
      @new_product = false
      @title = "Editing Product"
      @product = Product.find(params[:id])
      old_tag_ids = @product.tag_ids # for warnings later
    else
      @new_product = true
      @title = "New Product" # HTML page title, not product's title
      @product = Product.new
    end
 
    @product.attributes = params[:product] # actually performs a tag save...if the product already existed.  Which thing is wrong, again.

    if !@product.name.present? 
      # see if we should auto-fill
      tags_as_objects = params[:product][:tag_ids].select{|t| t.length > 0}.map{|id| Tag.find(id)}
      hymn_tag = tags_as_objects.detect{|t| t.is_hymn_tag?}
      composer_tag = tags_as_objects.detect{|t| t.is_composer_tag?}
      if hymn_tag && composer_tag
        @product.name = hymn_tag.name
      else
        flash[:notice] = "maybe you forgot to tag it with a hymn name or a composer, or (if it's an original) forgot to fill in the title?"      
      end
    end

    if @product.save

      # Now save product tags
      # Our method doesn't save tags properly if the product doesn't already exist.
      # Make sure it gets called after the product has an ID already
      if params[:product][:tag_ids]
         @product.tag_ids = params[:product][:tag_ids]  # re-assign, in case the .attributes= was on a "new" product so they weren't actually saved..which thing is so wrong...
         @product.sync_all_parent_tags
      else
        # regenerate doesn't have them...leave the same...
      end

      # Build product images from upload
      image_errors = []
      unless params[:image].blank?
        params[:image].each do |i|
          if i[:image_data] && !i[:image_data].blank?
            new_image = Image.new
            logger.info i.inspect
            logger.info i[:image_data].inspect
            # image_data is a file, really...
            new_image.uploaded_data = i[:image_data]
            if new_image.save
              @product.images << new_image
            else
              image_errors.push(new_image.filename + " " +  new_image.errors.map{|e| e.to_s}.join(' '))
            end
          end
        end
      end

      # it must just inspect the file?
      # Build downloads from form
      download_errors = []
      temp_file_path = "/tmp/temp_sheet_music_#{Process.pid}.png"

      unless params[:download_pdf_url].blank?
        url = params[:download_pdf_url]
        temp_file2 = "/tmp/incoming_#{Process.pid}.pdf"
        add_download url, temp_file2, 'application/pdf', 'pdf'
        out = `file #{temp_file2}`
        unless out =~ /PDF/
          flash[:notice] = 'warning--non pdf?' + url
        end
      end

      # do after the pdf for ordering sake...
      unless params[:download_mp3_url].blank?
        url = params[:download_mp3_url]
        type = 'audio/mpeg'
        if url =~ /\.(mid|midi)$/
          type = 'audio/midi'
        end 
        add_download url, temp_file_path, type, 'mp3'
        out = `file #{temp_file_path}`
        unless out =~ /MP3|MPEG|midi/i # MPEG? guess so...
           flash[:notice] = 'warning: mp3/midi upload was bad? + ' + url + ' ' + out
        end
      end

      unless params[:download].blank?
        n2 = 0 # outside the loops to allow for multiple pdfs
        # calculate highest previous image rank so it'll add 'em at the end...
        @product.images.each{ |old_image|
          old_image_rank = old_image.product_images[0].rank
          if old_image_rank
            old_image_rank += 1 # we want to come *after* this one
          else
            old_image_rank = 0 # we're ok here...
          end
          n2 = [old_image_rank, n2].max # calculate new max rank...
        }

        params[:download].each do |i|
          if i[:download_data] && !i[:download_data].blank?
            new_download = Download.new
            logger.info i[:download_data].inspect

            new_download.uploaded_data = i[:download_data]
            if i[:download_data].original_filename =~ /\.pdf$/i
              # also add them in as fake images
              got_one = false
              begin
                0.upto(1000) do |n|
                  command = "convert -density #{@@density} #{i[:download_data].path}[#{n}] #{temp_file_path}"
                  logger.info "running " + command
                  raise ContinueError unless system(command)
                  save_local_file_as_upload temp_file_path, 'image/png',  'sheet_music_picture.png', n2
                  n2 += 1
                  got_one = true
                end
              rescue ContinueError => e
                logger.info e.to_s # ok
              end
              raise 'failed to convert pdf' unless got_one
            end
            
            # and a hacky work-around for unknown file content types...I guess...
            if new_download.content_type == ""
              new_download.content_type = "application/#{new_download.name.split('.')[-1]}"
            end
            if new_download.save
              @product.downloads << new_download
            else
              download_errors.push(new_download.filename + " " + new_download.errors.map{|e| e.to_s}.join(' '))
            end
          end
        end
      end
      # cleanup
      FileUtils.rm_rf temp_file_path
      FileUtils.rm_rf temp_file2 if temp_file2

      # product was already saved...
      flash[:notice] ||= ''
      if @product.hymn_tag
        unless Tag.share_tags_among_hymns_products @product.hymn_tag
          flash[:notice] +=  "this hymn has no topics yet!"
        end
        @product.reload # it has new tags now

         if params[:product][:tag_ids]
           desired_tags = params[:product][:tag_ids].select{|id| !id.to_s.empty? }.map{|s| s.to_i}.sort
           if old_tag_ids && (old_tag_ids.sort == @product.tag_ids.sort) && (desired_tags != old_tag_ids.sort)
             flash[:notice] += "warning--you cannot remove a tag from something tagged with a hymn easily, have roger do it"
           end
         end

      end

      @product.clear_my_cache

      flash[:notice] += " Product '#{@product.name}' saved."
      flash[:notice] += @product.find_problems.map{|p| logger.info p.inspect;"<b>" + p + "</b><br/>"}.join('')
      if image_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload image(s) #{image_errors.join(',')}. This may happen if the size is greater than the maximum allowed of #{Image::MAX_SIZE / 1024 / 1024} MB!"
      end
      if download_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload file(s) #{download_errors.join(',')}."
      end
      if should_render
        redirect_to :action => 'edit', :id => @product.id
      end
    else # save failed
      @image = Image.new
      if @new_product
        render :action => 'new' and return
      else
        render :action => 'edit' and return
      end
    end
  end
  
  private
  def download full_url, to_here
    require 'open-uri'
    writeOut = open(to_here, "wb")
    writeOut.write(open(full_url).read)
    writeOut.close
  end

  def save_local_file_as_upload local_path, type, filename, rank
    new_image = Image.new
    fake_upload = Pathname.new(local_path)
    fake_upload.content_type = type
    fake_upload.original_filename = filename
    new_image.uploaded_data = fake_upload
    if new_image.save
      @product.images << new_image
      pi = new_image.product_images[0]
      pi.rank = rank
      pi.save
    else
      raise 'unexpected!'
    end
  end

  def add_download url, temp_file_path, type, extension_if_needed
    # psych it out ;)
    logger.info 'downloading to', temp_file_path
    download(url, temp_file_path)
    fake_upload = Pathname.new(temp_file_path)
     # http://hw.libsyn.com/p/e/e/0/ee058f5387587ba7/DormantSeason.mp3?sid=e22a787040b902c68d5680cfbe5ea065&l_sid=21117&l_eid=&l_mid=2660741&expiration=1325969215&hwt=28bdd0536f3512d6ba1d60cb3e38d23d -> DormanSeason.mp3
    fake_upload.original_filename = url.split('/')[-1].split('?')[0]
    fake_upload.original_filename += '.' + extension_if_needed unless fake_upload.original_filename =~ /\./
    fake_upload.content_type = type
    new_download = {:download_data => fake_upload}
    params[:download].unshift new_download # unshift so we can reuse that one filename...
  end

end

class Pathname
 attr_accessor :content_type, :original_filename
 alias :path :to_s # for pdf's .path sake...we're sure faking out whatever it's really supposed to be here...
end
