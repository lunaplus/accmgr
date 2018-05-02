var CHKEDIT = "chkEdit"
var HIDAID = "hidAID"
var TXTNM = "txtName"
var CHKISCD = "chkIscard"
var CHKISCDCHK = CHKISCD + "_chk"
var SELUID = "selUID"
var TXTBL = "txtBalance"
var LBLDT = "lblDate"

// edit checkbox
function chgEdit(){
    //var i = this.id.substring(this.id.length-1,this.id.length);
    var i = this.id.replace(new RegExp(CHKEDIT, "g"), "");
    chgDisabled(TXTNM+i, this.checked);
    chgDisabled(SELUID+i, this.checked);
    chgDisabled(TXTBL+i, this.checked);
    chgDisabled(HIDAID+i, this.checked);
    chgDisabled(CHKISCDCHK+i, this.checked);
    chgDisabled(CHKISCD+i, this.checked);
}

function chgIsCard(){
    var i = this.id.substring(this.id.length-1,this.id.length);
    chgOnOffValue(CHKISCD+i, this.checked);
}

function chgDisabled(id, enable){
    document.getElementById(id).disabled = (!enable);
}

function chgOnOffValue(id, enable){
    if(enable)
	document.getElementById(id).value = "on";
    else
	document.getElementById(id).value = "off";
}

// balance textbox
function onfocusBalance(){
    this.value = this.value.replace(/,/g, '');
}

function onblurBalance(){
    this.value =
        this.value
          .replace(/[^\d]/g, '')
          .replace(/(\d)(?=(\d{3})+$)/g, '$1,');
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

    // user sel
    var owner = document.getElementsByName(SELUID);
    for(var i=0; i<owner.length; i++){
	var elm = owner.item(i);
	if((!elm.disabled) && (elm.options[elm.selectedIndex].value==0)){
	    elm.focus();
	    alert('所有者は必須選択です。');
	    return false;
	}
    }

    // balance 
    var balance = document.getElementsByName(TXTBL);
    for(var i=0; i<balance.length; i++){
	var elm = balance.item(i);
	if((!elm.disabled) && (elm.value == "")){
	    elm.focus();
	    alert('残高は必須入力です。');
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
	document.getElementById(CHKISCDCHK+i).onchange = chgIsCard;
	var blnc = document.getElementById(TXTBL+i);
	blnc.onfocus = onfocusBalance;
	blnc.onblur = onblurBalance;
    }

    document.getElementById("submit").onclick = registerData;
}

window.addEventListener("DOMContentLoaded", init, false);
