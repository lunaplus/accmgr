var CHKEDIT = "chkEdit"
var HIDEID = "hidEID"
var TXTNM = "txtName"
var SELCLSFY = "selClsfy"

// edit checkbox
function chgEdit(){
    var i = this.id.substring(this.id.length-1,this.id.length);
    chgDisabled(TXTNM+i, this.checked);
    chgDisabled(SELCLSFY+i, this.checked);
    chgDisabled(HIDEID+i, this.checked);
}

function chgDisabled(id, enable){
    document.getElementById(id).disabled = (!enable);
}

// register edit data
function registerData(){
    if(!inputChk())
	return false;
    else if(confirm('登録してよろしいですか？'))
	return true;
    else
	return false;
}

function inputChk(){
    // checkEdit
    var edits = document.getElementsByName(CHKEDIT);
    existEdit = false;
    for(var i=0; i<edits.length; i++)
	existEdit = existEdit || edits.item(i).checked;
    if(!existEdit){
	alert('編集対象が選択されていません。');
	return false;
    }

    // account name
    var accname = document.getElementsByName(TXTNM);
    for(var i=0; i<accname.length; i++){
	var elm = accname.item(i)
	if((!elm.disabled) && (elm.value == "")){
	    elm.focus();
	    alert('口座名は必須入力です。');
	    return false;
	}
    }

    // classify sel
    var clsfy = document.getElementsByName(SELCLSFY);
    for(var i=0; i<clsfy.length; i++){
	var elm = clsfy.item(i);
	if((!elm.disabled) && (elm.options[elm.selectedIndex].value==0)){
	    elm.focus();
	    alert('費目区分は必須選択です。');
	    return false;
	}
    }

    return true;
}

// initialize
function init(){
    var tbl = document.getElementById("inputtable");
    for (var i=0; i<tbl.rows.length-1; i++){
	document.getElementById(CHKEDIT+i).onchange = chgEdit;
    }

    document.getElementById("submit").onclick = registerData;
}

window.addEventListener("DOMContentLoaded", init, false);
