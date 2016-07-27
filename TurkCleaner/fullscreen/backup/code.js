var maxNumExample = 25;

var currentIndex = -5;
var timerHandle;
var keyIsDown = false;

var testCount = 0;
var correctCount = 0;

var prevTodoCnt = 0;
var eventScript = '';

var loadedCount = 0;
var eventScript = '';


var categoryID;
var jobID;
var workerId;
var assignmentId;
var hitId;
var images2label = [];
var imagesOlabel = [];
var data = [];


function getFeedback(){
	if ( 0<=currentIndex && currentIndex< data.length && 'truth' in data[currentIndex] && 'feedback' in data[currentIndex] && (($('#holderDiv'+currentIndex).hasClass('target') && !data[currentIndex].truth) || ($('#holderDiv'+currentIndex).hasClass('noise') && data[currentIndex].truth))){
		alert('Are you sure? Your answer is wrong! Do you want to change it?');
		return false;
	}else{
		return true;
	}
}

function answerHit(){
	if ($('#holderDiv'+currentIndex).hasClass('target')){
		$('#holderDiv'+currentIndex).removeClass('target');
		$('#holderDiv'+currentIndex).addClass('noise');
	}else{
		$('#holderDiv'+currentIndex).addClass('target');
		$('#holderDiv'+currentIndex).removeClass('noise');
	}
}

function currentTime(){
	var d = new Date();
	return d.getTime();
}

$(window).keydown(function(e){
	e.preventDefault();
	var key = e.which | e.keyCode;

	eventScript = eventScript + currentTime() + 'up' + key + ';';

	if ( !keyIsDown){
	    if(key === 39 || key == 68){
	    	if (currentIndex+1<data.length && getFeedback()){
		    	keyIsDown = true;
				currentIndex = currentIndex + 1;
				displayFrame(currentIndex);
				timerHandle =setInterval(function(){
					if (currentIndex+1<data.length && getFeedback()){
						currentIndex = currentIndex + 1;
						displayFrame(currentIndex);
					}else{
						clearInterval(timerHandle);
					}
				},400);	    	
			}
	    }
	    if(key === 37 || key == 65){
			if (currentIndex-1>=0 && getFeedback()){
		    	keyIsDown = true;
				currentIndex = currentIndex - 1;
				displayFrame(currentIndex);
				timerHandle =setInterval(function(){
					if (currentIndex-1>=0 && getFeedback()){
						currentIndex = currentIndex - 1;
						displayFrame(currentIndex);
					}else{
						clearInterval(timerHandle);
					}
				},400);	    	
			}		    	
	    }
	}
	updateSubmitButton();
});


$(window).keyup(function(e){
	e.preventDefault();
	var key = e.which | e.keyCode;

	eventScript = eventScript + currentTime() + 'up' + key + ';';

    if(key === 32 ){
    	answerHit();
    }
    if(key === 37  || key == 65|| key === 39 || key == 68){
    	clearInterval(timerHandle);
    	keyIsDown = false;
    }
    updateSubmitButton();
});

function displayFrame(n){

	for (var i=-4;i<data.length+4;++i){
		$('#holderDiv'+i).hide();
		$('#holderDiv'+i).removeClass('focus3');	
		$('#holderDiv'+i).removeClass('focus2');	
		$('#holderDiv'+i).removeClass('focus1');	
		$('#holderDiv'+i).removeClass('focus');	
	}

	$('#holderDiv'+(n-4)).hide();
	$('#holderDiv'+(n-3)).show();	//	$('#holderDiv'+(n-3)).width(25);	$('#holderDiv'+(n-3)).height(25);
	$('#holderDiv'+(n-2)).show();	//	$('#holderDiv'+(n-2)).width(50);	$('#holderDiv'+(n-2)).height(50);
	$('#holderDiv'+(n-1)).show();	//	$('#holderDiv'+(n-1)).width(100);	$('#holderDiv'+(n-1)).height(100);
	$('#holderDiv'+n    ).show();	//	$('#holderDiv'+n    ).width(400);	$('#holderDiv'+n    ).height(400);
	$('#holderDiv'+(n+1)).show();	//	$('#holderDiv'+(n+1)).width(100);	$('#holderDiv'+(n+1)).height(100);
	$('#holderDiv'+(n+2)).show();	//	$('#holderDiv'+(n+2)).width(50);	$('#holderDiv'+(n+2)).height(50);
	$('#holderDiv'+(n+3)).show();	//	$('#holderDiv'+(n+3)).width(25);	$('#holderDiv'+(n+3)).height(25);
	$('#holderDiv'+(n+4)).hide();


	$('#holderDiv'+(n-3)).addClass('focus3');	$('#holderDiv'+(n-3)).removeClass('focus2');	
	$('#holderDiv'+(n-2)).addClass('focus2');	$('#holderDiv'+(n-2)).removeClass('focus1');  $('#holderDiv'+(n-2)).removeClass('focus3');	
	$('#holderDiv'+(n-1)).addClass('focus1');	$('#holderDiv'+(n-1)).removeClass('focus');   $('#holderDiv'+(n-1)).removeClass('focus2');	
	$('#holderDiv'+n    ).addClass('focus');	$('#holderDiv'+n    ).removeClass('focus1');
	$('#holderDiv'+(n+1)).addClass('focus1');	$('#holderDiv'+(n+1)).removeClass('focus');   $('#holderDiv'+(n+1)).removeClass('focus2');	
	$('#holderDiv'+(n+2)).addClass('focus2');	$('#holderDiv'+(n+2)).removeClass('focus1');  $('#holderDiv'+(n+2)).removeClass('focus3');	
	$('#holderDiv'+(n+3)).addClass('focus3');	$('#holderDiv'+(n+3)).removeClass('focus2');	


	if (!($('#holderDiv'+n).hasClass('target') || $('#holderDiv'+n).hasClass('noise') ) ){
		$('#holderDiv'+n).addClass('noise');			
	}
	$('#progressCNT').html((n+1)+'/'+data.length);
}


function getCurrentUTCtime(){
	var d =new Date();
	return d.toUTCString();
}

function updateServerLog(){
    var resultString = '';
	for (var i = 0; i<data.length; i++) {
		if ($('#holderDiv'+i).hasClass('target')){
			resultString = resultString + '1';
		}else if ($('#holderDiv'+i).hasClass('noise')){
			resultString = resultString + '0';
		}else{
			resultString = resultString + '?';
		}
	}


	var message = '{"time": "' + getCurrentUTCtime() + '", "assignmentId": "' + assignmentId + '","workerId": "' + workerId + '","hitId": "' + hitId + '","categoryID": "' + categoryID + '","jobID": "' + jobID + '","eventScript": "' + eventScript + '","resultString": "' + resultString + '"}';


    $.post("https://vision.princeton.edu/mturk/logJSON.cgi?",
    {
    	"path": categoryID + "/" + jobID + "/" + workerId + "/" + assignmentId,
	    "data": message
    },
    function(data) {
        try{
            if (data == 'success') {
            	console.log('Saved');
            }else{
                console.log('Failed');
                console.log(data);
            }
        }catch(err)
        {
            console.log('Failed');
            console.log(data);
        }
    });		
}

function getTodoCnt(){
	var todoCnt = 0;
    for (var i = 0; i<data.length; i++) {
    	if (!($('#holderDiv'+i).hasClass('target') || $('#holderDiv'+i).hasClass('noise'))){
    		++todoCnt;
    	}
    }
    return todoCnt;
}

function updateSubmitButton() {
    if (assignmentId == "ASSIGNMENT_ID_NOT_AVAILABLE")
    {
        document.getElementById('submitButton').disabled = 'disabled';
        document.getElementById('submitButton').value = 'You must ACCEPT the HIT before you can submit the results.';
    }else
    {
    	var todoCnt = getTodoCnt();
    	if (todoCnt==0){
		    document.getElementById('submitButton').disabled = '';
		    document.getElementById('submitButton').value = 'Submit';
        }else{
            document.getElementById('submitButton').disabled = 'disabled';
            document.getElementById('submitButton').value = 'Submit (' + todoCnt + ' images left)';
        }

        if (todoCnt > prevTodoCnt + data.length * 0.30){
        	prevTodoCnt = todoCnt;
	        updateServerLog();
        }
    }
}

function confirmSubmit()
{

	updateServerLog();

	eventScript = eventScript + currentTime() + 'sm;';		
    // convert the answer to text
    var resultString = '';
	for (var i = 0; i<data.length; i++) {
		if ($('#holderDiv'+i).hasClass('target')){
			resultString = resultString + '1';
		}else{
			resultString = resultString + '0';
		}
	}
    $('#answer').val(resultString);
   
    // deside hit type
    var ansPosCount = 0;
    for (var i = 0; i<data.length; i++) {
    	var answer = $('#holderDiv'+i).hasClass('target');
    	if (answer){
    	   ansPosCount++;
    	}
    }
    var hasMorePos = ansPosCount/data.length>0.5;

    correctCount = 0;
    var correctPosCount =0;
    var correctNegCount =0;
    var PosTestCount =0;
    var NegTestCount = 0;
	// caculate the accuracy
    for (var i = 0; i<data.length; i++) {
    	if ('truth' in data[i]){
    		var answer = $('#holderDiv'+i).hasClass('target');
    		if (data[i].truth){
    			PosTestCount++;
    		    if (answer== data[i].truth){
    		    	correctPosCount++;
    		    }
    		}
    		else{
    			NegTestCount++;
    			if (answer== data[i].truth){
    		    	correctNegCount++;
    		    }
    		}
    		
  			if (answer== data[i].truth){
    			correctCount++;
    		}
    	}
    }

    
	//var pass = (correctCount/testCount >= 0.90)&&((hasMorePos&&correctNegCount/NegTestCount >= 0.933)||(!hasMorePos&&correctPosCount/PosTestCount >= 0.933));
	var pass = (correctCount/testCount >= 0.80)&&((hasMorePos&&correctNegCount/NegTestCount >= 0.86)||(!hasMorePos&&correctPosCount/PosTestCount >= 0.86));
	
	if (pass){
	    $('#event').val(eventScript);
		return true;
	}else {
		eventScript = eventScript + currentTime() + 'rj;';
		alert("You accuracy is too low! You are not allowed to submit. Click [Cancel] to refine the results.");
		return false;
	}
}	

function leftButtonFun(){
	currentIndex = 0;
	displayFrame(currentIndex); 
	eventScript = eventScript + currentTime() + 'be;';
}

function rightButtonFun(){
	currentIndex = data.length-1;
	displayFrame(currentIndex); 
	eventScript = eventScript + currentTime() + 'en;';
	updateSubmitButton();
}



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

function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex ;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

    // Pick a remaining element...
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    // And swap it with the current element.
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
}

function submitCheck(){

    $.post("https://vision.princeton.edu/lsun/mturk/submit.cgi?",
    {
	    annotation: annotationURL,
       	data: JSON.stringify(objectToSave)
    },
    function(dataFromServer) {
        try{
            if (dataFromServer == 'success') {
				window.opener.notifyBack('DONE:'+'');

            }else{
                alert(dataFromServer);
            }
        }catch(err)
        {
            alert(dataFromServer);
        }
    });  
}



function imageLoaded(n){
	//console.log('id=' + n + ' count=' + loadedCount);
	loadedCount = loadedCount + 1;
	checkDisplay();

	eventScript = eventScript + currentTime() + 'ld' + n + ';';
}

function checkDisplay(){
	if (loadedCount < data.length){
		$('#loadingDiv').html('Image loading. '+loadedCount+' outof '+data.length+' are loaded.');
		$('#loadingDiv').show();
		$('#contentDiv').hide();
	}else{
		$('#loadingDiv').hide();
		$('#contentDiv').show();

		eventScript = eventScript + currentTime() + 'wk;';			
		updateServerLog();		
	}
}



function loadData(){
	$.ajaxSetup({ cache: false });
	//$.getJSON( "https://vision.princeton.edu/lsun/mturk/truth.cgi?categoryID="+categoryID, function( dataFromServer ) {
	$.getJSON( "https://vision.princeton.edu/lsun/mturk/truth/"+categoryID+".json", function( dataFromServer ) {
		imagesOlabel = dataFromServer;

		var tail = new Array();
		for (var i=0;i<images2label.length;++i){
			tail.push({"image": images2label[i], "tolabel": true});
		}
		for (var i=0;i<imagesOlabel.length;++i){
			if (!('feedback' in imagesOlabel[i])){
				tail.push(imagesOlabel[i]);
			}
		}
		tail = shuffle(tail);

		for (var i=0;i<imagesOlabel.length;++i){
			if (('feedback' in imagesOlabel[i])){
				data.push(imagesOlabel[i]);
			}
		}
		data = data.concat(tail);


		for (var i=-4;i<0;i++){
			$('#contentDiv').append('<div style="display: none;" id="holderDiv' + i + '"></div>');
		}
		for (var i=0;i<data.length;i++){

			$('#contentDiv').append('<div style="display: none;" id="holderDiv' + i + '"></div>');			
			$('#holderDiv' + i).append('<img id="holderImage' + i + '" src=""/>');
			$('#holderImage'+i).load(imageLoaded(i));
			$('#holderImage'+i).attr('src',data[i].image);
		}
		for (var i=data.length;i<data.length+4;i++){
			$('#contentDiv').append('<div style="display: none;" id="holderDiv' + i + '"></div>');
		}


		$('#contentDiv img').css('height',  ($( window ).height()-110) + 'px');

		//	displayFrame(0);
		currentIndex = 0;
		imageCount = data.length;
		displayFrame(0);

	}); 
}

function StartNow(categoryID_i,jobID_i,workerId_i,assignmentId_i,hitId_i){

	$('head').append('<link rel="stylesheet" href="https://vision.princeton.edu/pvt/TurkCleaner/fullscreen/style.css" type="text/css" />');

	$(window).resize(function (){$('#contentDiv img').css('height',  ($( window ).height()-110) + 'px');});

	categoryID = categoryID_i;
	jobID = jobID_i;
	workerId = workerId_i;
	assignmentId = assignmentId_i;
	hitId = hitId_i;
	$.getJSON( "https://vision.princeton.edu/lsun/mturk/job/"+categoryID+"/"+jobID+".json", function( dataFromServer ) {
		images2label = dataFromServer;
		loadData();
	});
	launchIntoFullscreen(document.getElementById('div2fullscreen'));
	//$('#div2fullscreen').
	$('#div2fullscreen').html('<div id="instructionDiv" style="width: 822px; height: 30px; text-align: center; margin-left: auto; margin-right: auto; font-size:30px; font-weight:bold;"> Is this <span style="color: #00F;" id="category_name">${question}</span>?&nbsp; (<span style="color: #F00;" >red: no</span>, <span style="color: #0F0;" >green: yes</span>)<input autocomplete="off" disabled="disabled" id="submitButton" onclick="return confirmSubmit()" type="submit" value="Submit" /> <input autocomplete="off" id="answer" name="answer" type="hidden" value="" /> <input autocomplete="off" id="event" name="event" type="hidden" value="" /></div><div id="definitionDiv" style="width: 822px; margin-left: auto; margin-right: auto; z-index: 10px; text-align: center; ">&nbsp;</div><div id="loadingDiv"><p>Images are loading. Please wait.</p></div><div id="instrDiv" style="display: none;"></div><div id="contentDiv" style="display: none; height: calc(100% - 80px); "></div><div id="progressDiv" style="text-align: center; padding-top: 5px;"><button id="leftButton" onclick="leftButtonFun(); " type="button"><img src="https://vision.princeton.edu/pvt/TurkCleaner/instruction/left.png" /></button>&nbsp; <span id="progressCNT" style="font-size:14px; font-weight: normal;">N/N</span> &nbsp;<button id="rightButton" onclick="rightButtonFun(); " type="button"><img src="https://vision.princeton.edu/pvt/TurkCleaner/instruction/right.png" /></button></div>');
	$.getJSON( "https://vision.princeton.edu/lsun/mturk/category/"+categoryID+".json", function( data ) {
		$("#category_name").html(data.name);
		$("#definitionDiv").html(data.definition);
	});
}


