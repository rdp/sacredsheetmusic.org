class QuestionsController < ApplicationController
  layout 'main'

  def index
    @title = "Questions"
  end

  def faq
    @title = "FAQ (Frequently Asked Questions)"
    @questions = Question.find(
      :all,
      :conditions => "featured = 1",
      :order => "-rank DESC, times_viewed DESC"
    )
  end

	# Ask a question, also known as /contact
	def ask
	  @title = "Contact us"
    	  @question = Question.new
         
          content_node = ContentNode.find(:first, :conditions => ["name = ?", params[:name]])
          if content_node
            # pre fill question text
            @snippet = content_node.content
            @question.long_question = "(Please fill in your email address <-----)\nSend me more info about the sheet music competition and composer potluck once you've got the dates!"
            @title = content_node.title
          elsif params[:pre_fill].present?
            @question.long_question = params[:pre_fill]
          end
	end
	
	def create_faq
	  @question = Question.new(params[:question])
		@question.short_question = "Message from the contact form"
    if !@question.save then
      flash.now[:notice] = 'There were some problems with the information you entered.<br/><br/>Please look at the fields below.'
      ask()
      render :action => 'ask'
    end
  end
	
	# Sends question via email to site owner
	def send_question
	  @question = Question.new(params[:question]) # what is a Question here? they used to save these?
	  @question.short_question = "Message from the contact form"
          email = params[:question][:email_address]
	  
	  if !@question.valid? || email !~ /@/ 
	    flash[:notice] = "Please enter an email address and message"
	    ask()
	    render :action => 'ask' and return
          else
	    begin
              text = params[:question][:long_question]
              if text.contain?("<a href=") || text.contain?("url=")
                raise "your question appears to have a link in it, which might mean it's spam, could you try editing it and try again, or send email directly to freeldssheetmusic@gmail.com instead please? (use the back button on your browser)"
              end
  
              OrdersMailer.deliver_inquiry(
                'Feedback/question from global site',
                params[:question][:long_question],
                params[:question][:email_address]
              )
              flash[:notice] = "Message sent successfully, thank you!"
              redirect_to '/' and return
            rescue => e
              flash[:notice] = "There was a problem sending your email please try again #{e}"
  	      ask()
  	      render :action => 'ask' and return
            end
          end
        end
	


end
