function oncheckPwd(){
    pwdchk = document.getElementById("pwdcheck");
    document.getElementById("newpwd").disabled = !pwdchk.checked;
    document.getElementById("cfnewpwd").disabled = !pwdchk.checked;

    if(!pwdchk.checked){
	document.getElementById("newpwd").value = "";
	document.getElementById("cfnewpwd").value = "";
	document.getElementById("newpwderr").innerHTML = "";
	document.getElementById("cfnewpwderr").innerHTML = "";
    }
    else
	checkNewpwd();
}

function oncheckDispNm(){
    dispchk = document.getElementById("dispnmcheck");
    document.getElementById("newdispnm").disabled = !dispchk.checked;

    if(!dispchk.checked){
	document.getElementById("newdispnm").value =
	    document.getElementById("curdispnm").innerHTML;
	document.getElementById("dispnmerr").innerHTML = "";
    }
    else
	checkDispnm();
}

function checkNewpwd(){
    pwdchk = document.getElementById("pwdcheck");
    target = document.getElementById("newpwd");
    prepare = document.getElementById("cfnewpwd");

    retval = true;

    if(pwdchk.checked){ //input check, when checkbox checked
	// check pwd text
	if(!(target.value.
	     match(/^(?=.*?[a-z])(?=.*?[A-Z])(?=.*?\d)[a-zA-Z\d]{8,100}$/))){
	    document.getElementById("newpwderr").innerHTML
		= "英大文字小文字数字の3種を含む8文字以上の文字列を設定してください。(記号は使えません)";
	    retval = false;
	}
	else
	    document.getElementById("newpwderr").innerHTML = "";
	
	// check confirm pwd text
	if (target.value != prepare.value){
	    document.getElementById("cfnewpwderr").innerHTML
		= "パスワードが一致しません。";
	    retval = false;
	}
	else
	    document.getElementById("cfnewpwderr").innerHTML = "";
    }
    return retval;
}

function checkDispnm(){
    target = document.getElementById("newdispnm");
    dispchk = document.getElementById("dispnmcheck");

    retval = true;

    if(dispchk.checked){ //input check, when checkbox checked
	if(target.value == document.getElementById("curdispnm").innerHTML){
	    document.getElementById("dispnmerr").innerHTML
		= "現在の表示名と同じです。";
	    retval = false;
	}
	else
	    document.getElementById("dispnmerr").innerHTML = "";
    }

    return retval;
}

function checkSubmit(){
    retval = (checkNewpwd() && checkDispnm());
    if(!retval)
	alert('入力エラーがあります。入力を確認してください');
    return retval;
}

function init(){
    document.getElementById("pwdcheck").onchange = oncheckPwd;
    document.getElementById("dispnmcheck").onchange = oncheckDispNm;
    document.getElementById("newpwd").onkeyup = checkNewpwd;
    document.getElementById("newpwd").onchange = checkNewpwd;
    document.getElementById("cfnewpwd").onkeyup = checkNewpwd;
    document.getElementById("cfnewpwd").onchange = checkNewpwd;
    document.getElementById("newdispnm").onkeyup = checkDispnm;
    document.getElementById("newdispnm").onchange = checkDispnm;

    document.getElementById("submitchange").onclick = checkSubmit;

    oncheckPwd();
    oncheckDispNm();
}

//loading function register
window.addEventListener("DOMContentLoaded", init, false);
