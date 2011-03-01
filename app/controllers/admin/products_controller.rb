require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/admin/products_controller"

class Admin::ProductsController < Admin::BaseController
  class ContinueError < StandardError; end

  def list
    @title = "All Product List (<a href=\"/admin_data/quick_search/product\">Other view</a>)"
    @products = Product.paginate(
    :order => "name ASC",
    :page => params[:page],
    :per_page => 30
    )
  end

  # Saves product from new and edit.
  #
  #
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
      temp_file_path = "/tmp/temp_sheet_music_#{Thread.current.object_id}.gif"
      unless params[:download].blank?
        n2 = 0 # outside the loop to allow for multiple pdfs

        @product.images.each{|old_image|
          n2 = [old_image.product_images[0].rank || 0, n2].max # calculate image rank so it'll add 'em at the end...
        }

        params[:download].each do |i|
          if i[:download_data] && !i[:download_data].blank?
            new_download = Download.new
            logger.info i[:download_data].inspect

            new_download.uploaded_data = i[:download_data]
            if i[:download_data].original_filename =~ /\.pdf$/
              # also add them in as fake images
              begin
                0.upto(1000) do |n|
                  raise ContinueError unless system("convert -density 125 #{i[:download_data].path}[#{n}] #{temp_file_path}")
                  save_local_file_as_upload temp_file_path, 'image/gif',  'sheet_music_picture.gif', n2
                  n2 += 1
                end
              rescue ContinueError => e
                logger.info e.to_s # ok
              end
            end
            
            # and a hacky work-around for unknown file types...
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

      if params[:download_mp3]
        url = params[:download_mp3]
        p 'downloading to', temp_file_path
        download(url, temp_file_path)
        save_local_file_as_upload temp_file_path, 'audio/mpeg', url.split('/')[-1], n2
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

      flash[:notice] = "Product '#{@product.name}' saved."
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
                  def fake_upload.content_type
                    type
                  end
                  def fake_upload.original_filename
                    filename
                  end
                  new_image.uploaded_data = fake_upload
                  if new_image.save
                    @product.images << new_image
                    # gets the rank wrong, except for the first? huh?
                    pi = new_image.product_images[0]
                    pi.rank = rank
                    pi.save
                    p 'saved one'
                  else
                    raise 'unexpected'
                  end
  end

end
