require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/admin/products_controller"

class Admin::ProductsController < Admin::BaseController
  class ContinueError < StandardError; end

  def list
    @title = "All Product List (<a href=\"/admin_data/quick_search/product\">Other view</a>)"
    @products = Product.paginate(
    :order => "name ASC",
    :page => params[:page],
    :per_page => params[:per_page] || 30
    )
  end

  @@density = 125 # seems reasonable...

  # Saves product from new and edit.
  #
  #
  def self.density= to_this
   @@density = to_this
  end

  def save
    # If we have ID param this isn't a new product
    if params[:id]
      @new_product = false
      @title = "Editing Product"
      @product = Product.find(params[:id])
    else
      @new_product = true
      @title = "New Product"
      @product = Product.new()
    end
    @product.attributes = params[:product]
    if @product.save
      # Save product tags
      # Our method doesn't save tags properly if the product doesn't already exist.
      # Make sure it gets called after the product has an ID
      @product.tag_ids = params[:product][:tag_ids] if params[:product][:tag_ids]
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
      temp_file_path = "/tmp/temp_sheet_music_#{Thread.current.object_id}.png"

      unless params[:download_pdf_url].blank?
        url = params[:download_pdf_url]
        temp_file2 = '/tmp/incoming.pdf' # only one won't hurt, right...? LODO delete
        add_download url, temp_file2, 'application/pdf', 'pdf'
        out = `file #{temp_file2}`
        unless out =~ /PDF/
          flash[:notice] = 'warning--non pdf?' + url
        end
      end

      # do after the pdf for ordering sake...
      unless params[:download_mp3_url].blank?
        url = params[:download_mp3_url]
        add_download url, temp_file_path, 'audio/mpeg', 'mp3'
        out = `file #{temp_file_path}`
        unless out =~ /MPEG/
           flash[:notice] = 'warning: mp3 upload was bad? + ' + url
        end
      end

      unless params[:download].blank?
        n2 = 0 # outside the loops to allow for multiple pdfs
        # calculate highest previous image rank so it'll add 'em at the end...
        @product.images.each{|old_image|
          n2 = [old_image.product_images[0].rank || 0, n2].max
        }

        params[:download].each do |i|
          if i[:download_data] && !i[:download_data].blank?
            new_download = Download.new
            logger.info i[:download_data].inspect

            new_download.uploaded_data = i[:download_data]
            if i[:download_data].original_filename =~ /\.pdf$/
              # also add them in as fake images
              got_one = false
              begin
                0.upto(1000) do |n|
                  command = "convert -density #{@@density} #{i[:download_data].path}[#{n}] #{temp_file_path}"
                  print command
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
      File.delete temp_file_path if File.exist?(temp_file_path)

      # Build variations from form
      if !params[:variation].blank?
        params[:variation].each do |v|
          variation = @product.variations.find_or_create_by_id(v[:id])
          variation.attributes = v
          variation.save
          @product.variations << variation
        end
      end

      flash[:notice] ||= ''
      flash[:notice] += " Product '#{@product.name}' saved."
      if @product.hymn_tag
        warnings = Tag.share_tags_among_hymns_products @product.hymn_tag
        flash[:notice] += warnings
      else
        if @product.topic_tags.length == 0
          flash[:notice] += "<br/> Warning: no topics associated with song yet."
        end
      end
      if image_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload image(s) #{image_errors.join(',')}. This may happen if the size is greater than the maximum allowed of #{Image::MAX_SIZE / 1024 / 1024} MB!"
      end
      if download_errors.length > 0
        flash[:notice] += "<b>Warning:</b> Failed to upload file(s) #{download_errors.join(',')}."
      end
      redirect_to :action => 'edit', :id => @product.id
    else
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
    fake_upload.original_filename = url.split('/')[-1]
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
