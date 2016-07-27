function StartNow(){

	$('#StartButton').html('Clicked');

	alert('hello from code.js');

	window.opener.notifyBack('i am done');
}

