var slideShowURL = 'SlideShow.html'; //parameter
var slideShowNS4URL = 'SlideShowNS4.html'; //parameter
var ns4 = false;

if( navigator.appName == "Netscape" )
{
    version = parseInt(navigator.appVersion);
    ns4=(version == 4);
}

function Slide(url, height, width, caption)
{
	this.url = url;
	this.height = height;
	this.width = width;
	this.caption = caption;
}

function openSlideShow(initialIndex) {

	var myWidth = (screen.availWidth > 800) ? (screen.availWidth - 100) : screen.availWidth;		// if 800x600 or less, take up
	var myHeight = (screen.availHeight > 600) ? (screen.availHeight - 100) : (screen.availHeight - 70);	// the whole screen.
	var myLeft = Math.round((screen.availWidth - myWidth) / 2);
	var myTop = Math.round((screen.availHeight - myHeight) / 2)-25;

	if (myTop < 0) { myTop = 0; }	// bugfix for Opera
	if (screen.availHeight < 600) { myTop-=20; }

	currentSlideIndex = initialIndex;//initialize the global

	var url = (ns4) ? slideShowNS4URL : slideShowURL;

	var slideWindow = window.open(url, 'slideshow', 'scrollbars=no,titlebar=no,location=no,status=no,toolbar=no,resizable=no,width='+myWidth+',height='+myHeight+',top='+myTop+',left='+myLeft);

	slideWindow.focus();
}


function openSlideShow2(initialIndex, language) {

	var myWidth = (screen.availWidth > 800) ? (screen.availWidth - 100) : screen.availWidth;		// if 800x600 or less, take up
	var myHeight = (screen.availHeight > 600) ? (screen.availHeight - 100) : (screen.availHeight - 70);	// the whole screen.
	var myLeft = Math.round((screen.availWidth - myWidth) / 2);
	var myTop = Math.round((screen.availHeight - myHeight) / 2)-25;

	if (myTop < 0) { myTop = 0; }	// bugfix for Opera
	if (screen.availHeight < 600) { myTop-=20; }

	currentSlideIndex = initialIndex;//initialize the global

	var url = (ns4) ? slideShowNS4URL : slideShowURL;

	var slideWindow = window.open(url + '?lang=' + language, 'slideshow', 'scrollbars=no,titlebar=no,location=no,status=no,toolbar=no,resizable=no,width='+myWidth+',height='+myHeight+',top='+myTop+',left='+myLeft);

	slideWindow.focus();
}
