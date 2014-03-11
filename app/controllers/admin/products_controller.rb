require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/admin/products_controller"

class Admin::ProductsController < Admin::BaseController
  class ContinueError < StandardError; end

  def spam_all_composers
    composers = Tag.find_by_name("composers").children
    #composers = [Tag.find_by_name "Melissa Pack"]
    spam_composers composers
  end

  def spam_composer
    if params[:id] && composer=(Tag.find_by_id(params[:id]))
      spam_composers [composer]
    else
      render :text => "not found spam_composer #{params.inspect}"
    end
  end

  def spam_composers composers
    count = 0
    for composer in composers
      next unless composer.composer_email_if_contacted.present?
      OrdersMailer.deliver_spam_composer(composer)
      count += 1
      sleep 0.2
      Rails.logger.info "sent spamser to #{composer.id}"
    end
    render :text => "spammed #{count} of them #{Time.now}"
  end

  def spam_all_composers_pre
   render :text => "now try spam_all_composers"
  end

  def single_composer_stats
    composer = Tag.find(params[:id]) 
    if composer
      OrdersMailer.deliver_composer_stats(composer)
      render :text => "statted #{composer.name}"
    else
      render :text => "not found #{params}"
    end
  end

  def list
   # we get here....
    @title = "All Songs List"
    @products = Product.paginate(
    :order => "name ASC",
    :page => params[:page],
    :per_page => params[:per_page] || 5,
    :include => [{:tags => [:parent, :children]}, :downloads] # just fer fun...
    )
  end

  def edit
    @product = Product.find(params[:id], :include => [{:tags => [:parent, :children]}, :downloads])
 
    @image = Image.new
    @header = "Editing #{@product.name}<br/>#{@product.code}"
    @title = "Editing #{@product.name} (#{@product.code})"
  end

  def with_problems
    @products = Product.find(:all, :include => [:downloads, {:tags => [:parent, :children]}])
    @products.select!{|p| 
      p.cached_find_problems.length > 0 
    }
    @title = 'all songs with any problems listed'
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

  def duplicate
    newy = duplicate_helper
    flash[:notice] = "editing the dup (you may need/want to clear its code now, if voicing is changing...)"
    redirect_to :action => :edit, :id => newy.id
  end

  def new_same_author
    newy = duplicate_helper
    newy.update_attribute(:description, '')
    newy.update_attribute(:name, '')
    # newy.save! # ??
    # youtube LOL
    bad_tags = newy.tags.select{|t| !t.is_composer_tag?}
    bad_tags.each{|t| newy.tags.delete t}
    flash[:notice] = "editing the new one by same author"
    redirect_to :action => :edit, :id => newy.id
  end

  def duplicate_helper preserve_tags=true
    raise 'no id?' unless id = params[:id]
    old = Product.find id
    attributes = old.attributes
    newy = Product.new
    newy.attributes = old.attributes
    newy.code = "auto_refresh_me_dupe_not_yet" # has no composer tag yet so give it a temp code for the init save so we can add tags
    newy.save!
    for tag in old.tags
      newy.tags << tag # force a save
    end
    newy.update_attribute(:code, "auto_refresh_me_dupe") # something about assigning .attributes up above is killing us with a normal assign then save...
    # newy.save! # ?? why broken?
    newy
  end

  # fix up any previously ugly images from pdf's
  def regenerate # images
    raise 'no id[s]?' unless id = params[:id]
    if id.contain? ','
      ids=id.split(',')
    else
      ids=[id]
    end
    for id in ids
      logger.info "regenerating for #{id}"
      regenerate_internal id
    end
    flash[:notice] = "regenerated images...#{ids.inspect}"
    redirect_to :action => :edit, :id => ids[0]
  end

  def self.regenerate_all_images this_servers_name # for running in irb prompt?
    products_with_images = Product.all(:include => :downloads).select{|p| p.downloads.detect{|dl| dl.name =~ /pdf$/i}}
    mini = products_with_images[0..2]
    out = []
    mini.each{|p|
      instance = self.new
      def instance.flash() 
        @flash ||= {} # OK this is getting stinky...
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
    logger.warn "no images #{id}?" unless product.images.count > 0
    old_images = product.images[0..-1] # force it to load images list so we get an old snapshot of the original images
    pdfs.each{|dl|
      # save it with our old url, then delete the original...hmm...yeah
      # resets ids! params[:product] = {:tag_ids => []}
      params[:id] = id # stinky!!!
      params[:product] = {} # doesn't  reset tags...
      params[:download] = []
      params[:download_pdf_url] = "http://" + this_servers_name_to_download_from + dl.relative_path_to_web_server
      logger.info params[:download_pdf_url]
      save_internal false
      dl.destroy # scaway :)
      old_count = dl.count
      # look for the new one after deleting the old so that we can easily know which is which for the count save :)
      new_download = product.reload.downloads.detect{|new_dl| new_dl.filename ==  dl.filename}
      new_download.count = old_count
      new_download.save
     }
     old_images.each{|i| i.destroy unless i.name =~ /\.(jpg|jpeg)$/i} # our one user contrib image is a jpeg :P
  end

  def save
    save_internal
  end

  def save_internal should_render = true
    logger.info "doing save"
    # If we have ID param this isn't a new product
    if params[:id]
      @new_product = false
      @title = "Editing Product"
      @product = Product.find(params[:id])
      old_tag_ids = @product.tag_ids # for warnings later
      logger.info "product #{params[:id]} started as #{@product.date_available}"
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

      image_errors = []
      temp_files=[]

      # add copy of old url, if requested [unused anymore DELETE ME]
      if params['re_use_url'] 
        if @product.composer_tag
          if old_prod = @product.composer_tag.products.detect{|p| p.original_url.present?}
            @product.original_url = old_prod.original_url
            @product.save
          elsif @product.composer_tag.composer_url.present?
            @product.original_url = @product.composer_tag.composer_url  
            @product.save
            image_errors.push("warning, using product's composer generic url, which might be expected...")
          else
            image_errors.push("check to re use url and has composer tag but has no songs with url's set and composer's url isn't set either, not setting it!")
          end
        else
          image_errors.push("check to re use url but no composer selected!")
        end
      end


      if params['suck_in_all_links']
        content = `curl #{@product.original_url}` # we already saved the product, so this should be available to us
        urls = URI.extract(content)
        urls.each{|link|
          if link =~ /\.pdf$/i
            temp_files << do_download_pdf(link)
          elsif link =~ /\.mp3$/i
            temp_files << do_download_mp3(link)
          end
        }
      end

      # Build product images from upload
      if params[:image].present?
        params[:image].each do |i|
          if i[:image_data].present?
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

      if params[:download_pdf_url].present?
        url = params[:download_pdf_url]
        temp_files << do_download_pdf(url)
      end

      # do after the pdf for ordering sake...
      if params[:download_mp3_url].present?
        url = params[:download_mp3_url]
        temp_files << do_download_mp3(url)
      end

      if params[:download].present?
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
          if i[:download_data].present?
            new_download = Download.new
            logger.info i[:download_data].inspect

            new_download.uploaded_data = i[:download_data]
            if i[:download_data].original_filename =~ /\.pdf$/i
              # also add them in as fake images
              got_one = false
              begin
                0.upto(1000) do |n|
                  use_scanned = false # results in thicker lines for normal pdf's that seem possibly harder to read
                  if use_scanned
                    command = "nice convert -density #{@@density*1.5} #{i[:download_data].path}[#{n}] -resize 66.66% -quality 90 #{temp_file_path}" # uses more cpu, at least...I think so. Enable for scanned documents...
                  else
                    command = "nice convert -density #{@@density} #{i[:download_data].path}[#{n}] -quality 90 #{temp_file_path}" # less cpu, ok for non scanned...odd
                  end
                  logger.info "running " + command
                  raise ContinueError unless system(command)
                  save_local_file_as_upload temp_file_path, 'image/png',  'sheet_music_picture.png', n2
                  n2 += 1
                  got_one = true
                end
              rescue ContinueError => e
                logger.info e.to_s # ok
              end
              unless got_one
                FileUtils.cp i[:download_data].path, "/tmp/latest_failure.pdf"
                raise 'failed to convert pdf' unless got_one
              end
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
      for file in temp_files
        FileUtils.rm_rf temp_file_path
      end

      # product was already saved...
      flash[:notice] ||= ''
      if @product.hymn_tag
        for tag in @product.hymn_tags
          unless Tag.share_tags_among_hymns_products tag
            flash[:notice] +=  "this hymn has no topics yet! #{tag.name}"
          end
        end
        @product.reload # it has new tags now

        if params[:product][:tag_ids]
          desired_tags = params[:product][:tag_ids].select{|id| !id.to_s.empty? }.map{|s| s.to_i}.sort
          if old_tag_ids && (old_tag_ids.sort == @product.tag_ids.sort) && (desired_tags != old_tag_ids.sort)
            flash[:notice] += "warning--you cannot remove a tag from something tagged with a hymn easily, have roger do it"
          end
        end

      end
 
      if @product.duplicate_download_md5s.length > 0
         flash[:notice] += "warning--appears song has duplicate downloads!"
      end

      flash[:notice] += " Product '#{@product.name}' saved."
      flash[:notice] += @product.find_problems.map{|p| logger.info p.inspect;"<b>" + p + "</b><br/>"}.join('')
      if image_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload image(s) #{image_errors.join(',')}. This may happen if the size is greater than the maximum allowed of #{Image::MAX_SIZE / 1024 / 1024} MB!"
      end
      if download_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload file(s) #{download_errors.join(',')}."
      end
      logger.info "ended as #{@product.date_available}"
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
  def do_download_mp3 url
    temp_file2 = "/tmp/incoming_#{Process.pid}_#{(rand*1000000).to_i}.mp3"
    type = 'audio/mpeg'
    if url =~ /\.(mid|midi)$/
      type = 'audio/midi'
    end 
    add_download url, temp_file2, type, 'mp3'
    out = `file #{temp_file2}`
    unless out =~ /MP3|MPEG|midi|Audio/i
       flash[:notice] = "warning: mp3/midi upload was bad? #{url} [#{out}] file #{temp_file_path}"
    end
    temp_file2
  end

  def do_download_pdf url
    temp_file2 = "/tmp/incoming_#{Process.pid}_#{(rand*1000000).to_i}.pdf"
    add_download url, temp_file2, 'application/pdf', 'pdf'
    out = `file #{temp_file2}`
    unless out =~ /PDF/
      flash[:notice] = 'warning--non pdf?' + url
    end
    temp_file2
  end

  def download full_url, to_here
    require 'open-uri'
    retrieved = open(full_url).read
    writeOut = open(to_here, "wb")
    writeOut.write(retrieved)
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
     # http://hw.libsyn.com/p/e/e/0/ee058f5387587ba7/DormantSeason.mp3?sid=e22a78704&mid=a1d60cb3e38d23d -> DormanSeason.mp3 where applicable
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
