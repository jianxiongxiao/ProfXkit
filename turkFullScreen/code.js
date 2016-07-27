function launchIntoFullscreen(element) {
  if(element.requestFullscreen) {
    element.requestFullscreen();
  } else if(element.mozRequestFullScreen) {
    element.mozRequestFullScreen();
  } else if(element.webkitRequestFullscreen) {
    element.webkitRequestFullscreen();
  } else if(element.msRequestFullscreen) {
    element.msRequestFullscreen();
  }
}

function StartNow(){
	launchIntoFullscreen(document.getElementById('div2fullscreen'));

	//$('#StartButton').html('Clicked');

	alert('StartNow from code.js');

	window.opener.notifyBack('i am done');
}

