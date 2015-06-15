// slideshow.js
//
// Copyright 2001. Apple Computer, Inc. All rights reserved.
// Part of HomePage 3.0
//
// Change Log:
//
// 11/1/2001	GKM		Changed behavior of slides to loop instead of stopping at both ends of the slideshow

	var slides = opener.slides;

	var ie = false;
	var ns = false;
	var ns4 = false;
	var ns6 = false;
	var opera = false;
	var iCab = false;
	
	var widthMargin = 60;
	var heightMargin = 120;
	var contentWidthMargin = 20;
	var contentHeightMargin = 20;

	var mainImage;
	var mainviewDiv = null;
	var mainWidth = 0;		// the width of the main picture
	var mainHeight = 0;

	var showCaption = true;

	var globalInterval;



isLoadedImage = null
function isItLoaded()
{
	if( mainImage.complete )
	{
//		alert(mainImage.src + " done");
		clearInterval(globalInterval);
		
		if( currentSlideIndex() != maxIndex() )
		{
			if(!isLoadedImage) {
				isLoadedImage = new Image();
			}
			isLoadedImage.src = slides[currentSlideIndex() + 1].url;
		}
	}
}

function pollForLoaded()
{
	clearInterval(globalInterval);
	
	globalInterval = setInterval("isItLoaded()", 150);
}

function currentSlideIndex()
{
	return opener.currentSlideIndex;
}

function maxIndex()
{
	return slides.length - 1;
}

var previousSelectedIndex = null;
function incrementIndex()
{
	previousSelectedIndex = opener.currentSlideIndex;
	if (++opener.currentSlideIndex > maxIndex())
		opener.currentSlideIndex = 0;		// loop around to the start
	
}

function decrementIndex()
{
	previousSelectedIndex = opener.currentSlideIndex;
	if (--opener.currentSlideIndex < 0)
		opener.currentSlideIndex = maxIndex();	// loop around to the end
}

/*
	this.version=navigator.appVersion;
	this.v=parseInt(this.version);
*/
function initEnvironment()
{
	if( navigator.appName == "Netscape" )
	{
		version = parseInt(navigator.appVersion);
                ns=(version >= 4);
                ns4=(version == 4);
                ns6=(version == 5);
	}
	else if( navigator.userAgent.indexOf("iCab") != -1 )
	{
		iCab = true;
	}
	else if( navigator.userAgent.indexOf("Opera") != -1 )
	{
		opera = true;
	}
	else if( navigator.userAgent.indexOf("MSIE") != -1 )
	{
		ie = true;
	}

	if( (ns4) && (!opener.isPureISOLatin1) )
	{
		showCaption = false;
	}
	else
	{
		showCaption = true;
	}
}

initEnvironment();

function getInsideWindowWidth()
{
	if( ie )
	{
		return document.body.clientWidth;
	}
	else
	{
		return window.innerWidth;
	}
}

function getInsideWindowHeight()
{
	if( ie )
	{
		return document.body.clientHeight;
	}
	else
	{
		return window.innerHeight;
	}
}

function mainViewOnLoad()
{
	if(mainviewDiv) {
		mainviewDiv.style.visibility="hidden";
		mainviewDiv.style.visibility="visible";
	}
}

function previousSelectedSize()
{
	return sizeAtIndex(previousSelectedIndex);	
}

function currentSize()
{
	return sizeAtIndex(currentSlideIndex());
}

function sizeAtIndex(index)
{
	var result = {};
	var currentWidth = slides[index].width;
	var	currentHeight = slides[index].height;
	var aspectRatio = currentWidth / currentHeight;

	if( currentWidth > mainWidth ) // adjust for frame size
	{
		currentWidth = mainWidth;
		currentHeight = parseInt(mainWidth / aspectRatio,10);
		
		if( currentHeight > mainHeight )	// in case of really tall images
		{
			currentHeight = mainHeight;
			currentWidth = parseInt(mainHeight * aspectRatio,10);
		}
	}
	else if( currentHeight > mainHeight )
	{
		currentHeight = mainHeight;
		currentWidth = parseInt(mainHeight * aspectRatio,10);	

		if (currentWidth > mainWidth) // in case of really wide images
		{
			currentWidth = mainWidth;
			currentHeight = parseInt(mainWidth / aspectRatio,10);
		}
	}
	result.width = currentWidth;
	result.height = currentHeight;
	return result;
}

function openCurrentImage()
{
	var myWidth = (screen.availWidth > 800) ? (screen.availWidth - 100) : screen.availWidth;		// if 800x600 or less, take up
	var myHeight = (screen.availHeight > 600) ? (screen.availHeight - 100) : (screen.availHeight - 70);	// the whole screen.
	var myLeft = Math.round((screen.availWidth - myWidth) / 2);
	var myTop = Math.round((screen.availHeight - myHeight) / 2)-25;

	if (myTop < 0) { myTop = 0; }	// bugfix for Opera
	if (screen.availHeight < 600) { myTop-=20; }

	myWidth = (slides[currentSlideIndex()].width < myWidth) ? slides[currentSlideIndex()].width : myWidth;
	myHeight = (slides[currentSlideIndex()].height < myHeight) ? slides[currentSlideIndex()].height : myHeight;

	openCurrentImageWindow = window.open(slides[currentSlideIndex()].url, 'SlideShowFullSizeImage', 'scrollbars=yes,titlebar=no,location=no,status=no,toolbar=no,resizable=yes,width='+ myWidth +',height='+ myHeight +',top='+'0'+',left='+'0');
	openCurrentImageWindow.document.body.leftMargin = 0; openCurrentImageWindow.document.body.topMargin = 0;
}

function setMainImage()
{
	var currentWidth = currentSize().width;
	var	currentHeight = currentSize().height;

	if(ns) {

		if( ns4 )
		{
			var myMainImageiLayer = document.mainImageiLayer;
			var nsImage = myMainImageiLayer.document.mainImageLayer;
			var dropShadowExtra = 6;

			var previousSize = previousSelectedSize();

			if(!slides[previousSelectedIndex].position) {
				var previousPosition = {};
				previousPosition.x = myMainImageiLayer.left;
				previousPosition.y = myMainImageiLayer.top;
				slides[previousSelectedIndex].position = previousPosition;
			}

			if(!slides[currentSlideIndex()].position) {
				var previousPosition = {};

                newX = myMainImageiLayer.left + Math.ceil((previousSize.width - currentWidth) / 2);
                newY = myMainImageiLayer.top + Math.ceil((previousSize.height - currentHeight) / 2);

				previousPosition.x = newX;
				previousPosition.y = newY;
				slides[currentSlideIndex()].position = previousPosition;
			}
			else {	
				newX = slides[currentSlideIndex()].position.x
				newY = slides[currentSlideIndex()].position.y
			}

			myMainImageiLayer.left = newX
			myMainImageiLayer.top = newY;
			myMainImageiLayer.clip.width = currentWidth+dropShadowExtra
			myMainImageiLayer.clip.height = currentHeight+dropShadowExtra;
			//nsImage.clip.width = currentWidth+dropShadowExtra;
			//nsImage.clip.height = currentHeight+dropShadowExtra;

			nsImage.document.write('<table border="0" cellspacing="0" cellpadding="0"><tr><td width="3"><img src="frame_topleftcorner.gif" alt="" height="3" width="3" border="0"></td><td background="frame_topbg.gif"><img src="frame_topbg.gif" alt="" height="3" width="3" border="0"></td><td width="3"><img src="frame_toprightcorner.gif" alt="" height="3" width="3" border="0"></td></tr><tr><td width="1" background="frame_leftbg.gif"><img src="frame_leftbg.gif" alt="" height="3" width="1" border="0"></td><td><a onFocus = "this.blur();" href="javascript:openCurrentImage()"><img name="mainview" src="' + slides[currentSlideIndex()].url + '" width="' + currentWidth + '" height="' + currentHeight + '" border="0"></a></td><td width="1" background="frame_rightbg.gif"><img src="frame_rightbg.gif" alt="" height="3" width="1" border="0"></td></tr><tr><td width="3"><img src="frame_botleftcorner.gif" alt="" height="3" width="3" border="0"></td><td background="frame_botbg.gif"><img src="frame_botbg.gif" alt="" height="3" width="3" border="0"></td><td width="3"><img src="frame_botrightcorner.gif" alt="" height="3" width="3" border="0"></td></tr></table>\n\n');


			nsImage.document.close();

		}
		else {
			mainviewDiv = document.getElementById('mainviewDiv');
			//mainviewDiv.style.visibility = 'hidden';

			mainviewDiv.innerHTML = '<a onFocus = "this.blur();" href="javascript:openCurrentImage()"><img name="mainview" src="' + slides[currentSlideIndex()].url + '" width="' + currentWidth + '" height="' + currentHeight + '" border="0"></a>';

/*
			This following code works but there's an annoying artefact when 2 foowing images don't have the same size.

			//mainImage.src = "spacer.gif";
			mainImage.width = currentWidth;
			mainImage.height = currentHeight;
			mainImage.src = slides[currentSlideIndex()].url;
*/
			//mainviewDiv.style.visibility = 'visible'

			pollForLoaded();

		}
	}
	else
	{
		if(!iCab) mainImage.src = "spacer.gif";
		if( ie || ns6 || iCab)
		{
			mainImage.width = currentWidth;
			mainImage.height = currentHeight;
		}
		mainImage.src = slides[currentSlideIndex()].url;
		//Don't ask. if done twice, iCab is fine, otherwise the image randomely doesn't show up
		if(iCab) mainImage.src = slides[currentSlideIndex()].url;

		//alert(mainImage.complete);
		if(!iCab ) pollForLoaded();
	}
}


var backDisabled = "btn_back0.gif";
var backEnabled = "btn_back1.gif";

var forwardDisabled = "btn_next0.gif";
var forwardEnabled = "btn_next1.gif";

function getPrevImage()
{
	decrementIndex();
			
	setMainImage();

	document.images['nextButton'].src = forwardEnabled;
	
	writeCaption();
}

function getNextImage()
{	
	incrementIndex();
	
	setMainImage();

	document.images['backButton'].src = backEnabled;
	
	writeCaption();
}

function hasCurrentCaption() {
	if(slides[currentSlideIndex()].caption.length > 0) {
		return true;
	}
	return false;
}

var _captionFrame = null;
function captionFrame()
{
	if(!_captionFrame) {
        if( ns4 ) {
        	_captionFrame = document.captionFrameiLayer;
		}
        else if( ns6 )
        {
            _captionFrame = document.getElementById('captionFrame');
        }
        else if( ie )
        {
            _captionFrame = document.all.captionFrame;
        }
        else
        {
            _captionFrame = document.getElementById('captionFrame');
        }
	}
	return _captionFrame;
}

function setCaptionFrameVisible(flag) {

	    if(flag) {
			if(ns4) {
                captionFrame().visibility = "show";
			}
			else {
                if(captionFrame()) captionFrame().style.visibility = "visible";
			}
	    }
	    else {
			if(ns4) {
                captionFrame().visibility = "hide";
			}
			else {
                if(captionFrame()) captionFrame().style.visibility = "hidden";
			}
	    }

}

var _captionLayer= null;
function captionLayer()
{


	if(! _captionLayer) {
        if( ns4 ) {
        	//_captionLayer = document.captionFrameiLayer.document.captionFrame.document.captioniLayer.document.captionLayer;
        	_captionLayer = document.captionFrameiLayer.document.captionFrame;
        	//_captionLayer = document.captioniLayer.document.captionLayer;
		}
        else if( ns6 )
        {
            _captionLayer = document.getElementById('captionDiv');
        }
        else if( ie )
        {
            _captionLayer = document.all.captionDiv;
        }
        else
        {
            _captionLayer = document.getElementById('captionDiv');
        }
	}
	return _captionLayer;
}

function setCaption(caption)
{
	if( ! caption ) caption = '';

    if( ns )
    {
    	var escapedCaption = caption;
    	escapedCaption = escapedCaption.replace(/&/g, "&amp;");
    	escapedCaption = escapedCaption.replace(/</g, "&lt;");
    	escapedCaption = escapedCaption.replace(/>/g, "&gt;");

        if( ns4 )
        {
           	//captionLayer().document.write('<span class="caption">' + escapedCaption + '</span>');
           	captionLayer().document.write('<table border="0" cellspacing="0" cellpadding="0"><tr><td align=right><img src="caption_well_left.gif" alt="" height="39" width="15" border="0"></td><td align="center" width="443" background="caption_bg.gif">'+'<span class="caption">' + escapedCaption + '</span>'+'</td><td><img src="caption_well_right.gif" alt="" height="39" width="15" border="0"></td></tr></table>');
            captionLayer().document.close();

        }
        else if( ns6 )
        {
            captionLayer().innerHTML = escapedCaption;
        }
    }
    else if( ie )
    {
        captionLayer().innerText = caption;
    }
    else
    {
        captionLayer().innerHTML = caption;
    }
}


function writeCaption()
{
	if( !showCaption ) { return; }

	else if(!hasCurrentCaption()) {
		setCaption('&nbsp;');
        setCaptionFrameVisible(false);
	}
	else {
		setCaption(slides[currentSlideIndex()].caption);
        setCaptionFrameVisible(true);
	}
}

actionURLRandomifier = 0;
function randomizedURL(url) 
{
	var result = url+'&_rd='+ actionURLRandomifier;
	actionURLRandomifier++;
	return result;
}

function sendFeedback()
{
	var url = opener.feedbackURL+'&index='+opener.currentSlideIndex;
	var width;
	var height;

	if(ns||opera) {
		//alert('opener.screenX = '+ opener.screenX+', opener.screenY = '+ opener.screenY);
		width = opener.innerWidth;
		height = opener.innerHeight;
		var feedbackWindow = window.open(randomizedURL(url), 'Feedback', 'scrollbars=yes,titlebar=yes,location=yes,status=yes,toolbar=yes,menubar=yes,personalbar=yes,resizable=yes,width='+width+',height='+ height+',screenY='+ opener.screenY +',screenX='+ opener.screenX);
	}
	else {
		//alert('opener.screenLeft = '+ opener.clientX +', opener.screenTop = '+ opener. screenTop);
		width = opener.document.body.clientWidth;
		height = opener.document.body.clientHeight;
		var feedbackWindow = window.open(randomizedURL(url), 'Feedback', 'scrollbars=yes,titlebar=yes,location=yes,status=yes,toolbar=yes,menubar=yes,personalbar=yes,resizable=yes,width='+width+',height='+ height+',top='+ opener.screenTop+',left='+ opener.screenLeft);
	}



	//var feedbackWindow = window.open(randomizedURL(url), 'Feedback', 'scrollbars=yes,titlebar=yes,location=yes,status=yes,toolbar=yes,menubar=yes,personalbar=yes,resizable=yes,width='+width+',height='+ height+',top='+ opener.top+',left='+ opener.left);
	//var feedbackWindow = window.open(randomizedURL(url), 'Feedback', 'scrollbars=yes,titlebar=yes,location=yes,status=yes,toolbar=yes,menubar=yes,personalbar=yes,resizable=yes,width='+width+',height='+ height+',screenY='+ opener.screenY +',screenX='+ opener.screenX);

}

function initPage()
{
	mainImage = document.images['mainview'];
	contentWidth  = getInsideWindowWidth()  - widthMargin;
	contentHeight = getInsideWindowHeight() - heightMargin;

	mainWidth  = contentWidth  - contentWidthMargin;
	mainHeight = contentHeight - contentHeightMargin;

	//setMainImage();

	if( ie )
	{
		document.all.mainImageDiv.style.visibility = 'visible';
	}
	else if(ns6) {
		document.getElementById('mainImageDiv').style.visibility = 'visible';

	}
	else if(ns4)
	{
		document.mainImageiLayer.visibility = 'visible';
	}
	else if(iCab) {
		document.getElementById('mainImageDiv').style.visibility = 'visible';
	}

	if(ns4) writeCaption();
}

function writeFeedbackButton ()
{
                    if(opener.showFeedbackButton) {
						var buttonImageName;
						var	feedbackEnabled = opener.feedbackEnabled;
						var language = getQueryStringValue("lang");						
						
						if(!language || (typeof(language) == "undefined")) {
							language = navigator.language;
						}				
						
						if(!language || (typeof(language) == "undefined")) {
							language = navigator.userLanguage;
						}
						

						if(!language) language = 'en';

						language = language.substring(0,2);

						if(language == 'ja') {
							if(feedbackEnabled) {
								buttonImageName = "btn_sendfeedback_ja.gif"
							}
							else {
								buttonImageName = "btn_sendfeedback_ja_disabled.gif"
							}
						}
						else {
							if(feedbackEnabled) {
								buttonImageName = "feedback_btn.jpg"
							}
							else {
								buttonImageName = "feedback_btn_disabled.jpg"
							}
						}
                        if(feedbackEnabled) {
                            document.write('<a href="javascript:void sendFeedback()" onfocus="blur()"><img src="'+ buttonImageName+'" border="0"></a>');
                        }
                        else {
                            document.write('<img src="'+ buttonImageName+'" border="0">');
                        }
                    }
}


function getQueryStringValue(key)
{
	var value = null;
	var query = window.location.search.substring(1);
	var pairs = query.split("&");
	
	
	for (var i=0;i<pairs.length;i++)
	{
		var pos = pairs[i].indexOf('=');
		if (pos >= 0)
		{
			if (pairs[i].substring(0,pos) == key)
				value = pairs[i].substring(pos+1);
			break;
		}
		
	}
	return value;
}


