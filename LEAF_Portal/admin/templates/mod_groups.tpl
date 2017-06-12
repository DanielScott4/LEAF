<div id="sideBar" style="float: right; width: 150px">
    <div class="buttonNorm" onclick="createGroup();" style="font-size: 120%"><img src="../../libs/dynicons/?img=list-add.svg&w=32" alt="Create Group" /> Create Group</div><br />
</div>
<br style="clear: both" />
<div>
    <span style="font-size: 18px; font-weight: bold">List of Groups</span>
    <br /><br />

    <div id="groupList"></div>
</div>

<br style="clear: both" />

<!--{include file="site_elements/generic_xhrDialog.tpl"}-->
<!--{include file="site_elements/generic_simple_xhrDialog.tpl"}-->

<script type="text/javascript">
/* <![CDATA[ */

function getMembers(groupID) {
    $.ajax({
        url: "ajaxJSON.php?a=mod_groups_getMembers&groupID=" + groupID,
        dataType: "json",
        success: function(response) {
            $('#members' + groupID).fadeOut();
            populateMembers(groupID, response);
            $('#members' + groupID).fadeIn();
        }
    });
}

function populateMembers(groupID, members) {
    $('#members' + groupID).html('');
    for(var i in members) {
        $('#members' + groupID).append(members[i].Lname + ', ' + members[i].Fname + '<br />');
    }
}

function addAdmin(userID) {
    $.ajax({
        type: 'POST',
        url: "ajaxIndex.php?a=add_user",
        data: {'userID': userID,
               'groupID': 1,
               'CSRFToken': '<!--{$CSRFToken}-->'},
        success: function(response) {
        	getMembers(1);
        }
    });
}

function removeAdmin(userID) {
    $.ajax({
    	type: 'POST',
        url: "ajaxIndex.php?a=remove_user",
        data: {'userID': userID,
        	   'groupID': 1,
        	   'CSRFToken': '<!--{$CSRFToken}-->'},
        success: function(response) {
        	getMembers(1);
        }
    });
}

function getGroupList() {
    $('#groupList').html('<div style="border: 2px solid black; text-align: center; font-size: 24px; font-weight: bold; background: white; padding: 16px; width: 95%">Loading... <img src="../images/largespinner.gif" alt="loading..." /></div>');

    $.ajax({
        type: 'GET',
        url: "../api/group/members",
        dataType: "json",
        success: function(res) {
            $('#groupList').html('');
            for(var i in res) {

            	// only show explicit groups, not ELTs
            	if(res[i].parentGroupID == null) {
                    $('#groupList').append('<div id="'+ res[i].groupID +'" title="groupID: '+ res[i].groupID +'" class="groupBlock">\
                            <h2 id="groupTitle'+ res[i].groupID +'">'+ res[i].name +'</h2>\
                            <div id="members'+ res[i].groupID +'"></div>\
                            </div>');
            	}

                if(res[i].groupID != 1) { // if not admin
                    $('#' + res[i].groupID).on('click', function(groupID, parentGroupID) {
                        return function() {
                        	dialog_simple.setContent('<iframe src="<!--{$orgchartPath}-->/?a=view_group&groupID=' + groupID + '&iframe=1" style="width: 99%; height: 99%; border: 0px; background:url(../images/largespinner.gif) center top no-repeat;"></iframe>');

                        	dialog_simple.setCancelHandler(function() {
                                $.ajax({
                                    type: 'GET',
                                    url: '../api/?a=system/updateGroup/' + groupID,
                                    success: function() {
                                        getMembers(groupID);
                                    },
                                    cache: false
                                });
                        	});
                        	dialog_simple.show();
                        };
                    }(res[i].groupID, res[i].parentGroupID));
                }
                else { // if is admin
                	$('#' + res[i].groupID).on('click', function() {
                		dialog.setContent('<h2>System Administrators</h2><div id="adminList"></div><br /><h3>Add Administrator:</h3><div id="employeeSelector"></div>');

                        empSel = new nationalEmployeeSelector('employeeSelector');
                        empSel.apiPath = '<!--{$orgchartPath}-->/api/?a=';
                        empSel.rootPath = '<!--{$orgchartPath}-->/';
                        empSel.outputStyle = 'micro';
                        empSel.initialize();

                        dialog.setSaveHandler(function() {
                        	if(empSel.selection != '') {
                                var selectedUserName = empSel.selectionData[empSel.selection].userName;
                                $.ajax({
                                    type: 'POST',
                                    url: '<!--{$orgchartPath}-->/api/employee/import/_' + selectedUserName,
                                    data: {CSRFToken: '<!--{$CSRFToken}-->'},
                                    success: function(res) {
                                        if(!isNaN(res)) {
                                        	addAdmin(selectedUserName);
                                        }
                                        else {
                                            alert(res);
                                        }
                                    }
                                });
                        	}
                        	dialog.hide();
                        });
                	    $.ajax({
                	        url: "ajaxJSON.php?a=mod_groups_getMembers&groupID=1",
                	        dataType: "json",
                	        success: function(res) {
                	        	$('#adminList').html('');
                	        	var counter = 0;
                	            for(var i in res) {
                	            	$('#adminList').append('<div>&bull; '+ res[i].Lname  + ', ' + res[i].Fname +' [ <a href="#" id="removeAdmin_'+ counter +'">Remove</a> ]</div>');
                	            	$('#removeAdmin_' + counter).on('click', function(userID) {
                	            		return function() {
                                            removeAdmin(userID);
                                            dialog.hide();
                	            		};
                	            	}(res[i].userName));
                	            	counter++;
                	            }
                	        }
                	    });
                		dialog.show();
                	})
                }
                populateMembers(res[i].groupID, res[i].members);
            }
        },
        cache: false
    });
}

function createGroup() {
    dialog.setTitle('Create new group');
    dialog.setContent('<br />Group Title: <div id="groupSel_container"></div><br />Note: If the group already exists, you may import it.');
    
    var groupSel = new groupSelector('groupSel_container');
    groupSel.apiPath = '<!--{$orgchartPath}-->/api/?a=';
    groupSel.basePath = '../';
    groupSel.setResultHandler(function() {
    	if(groupSel.numResults == 0) {
    		groupSel.hideResults();
    	}
    	else {
    		groupSel.showResults();
    	}

    	// prevent services from showing up as search results
    	for(var i in groupSel.jsonResponse) {
    		if(groupSel.jsonResponse[i].tags.service != undefined) {
    			$('#' + groupSel.prefixID + 'grp' + groupSel.jsonResponse[i].groupID).css('display', 'none');
    		}
    	}
    });
    groupSel.initialize();
    
    function tagAndUpdate(groupID) {
        $.when(
                $.ajax({
                    type: 'POST',
                    url: '<!--{$orgchartPath}-->/api/?a=group/'+ groupID + '/tag',
                    data: {
                        tag: '<!--{$orgchartImportTag}-->',
                        CSRFToken: '<!--{$CSRFToken}-->'
                    },
                    success: function() {
                    }
                }),
                $.ajax({
                    type: 'GET',
                    url: '../api/?a=system/updateGroup/' + groupID,
                    success: function() {
                    },
                    cache: false
                })
            ).then(function() {
                window.location.reload();
            });
    }
    
    dialog.setSaveHandler(function() {
    	if(groupSel.selection == '') {
            $.ajax({
                type: 'POST',
                url: '<!--{$orgchartPath}-->/api/?a=group',
                data: {title: $('#' + groupSel.prefixID + 'input').val(),
                       CSRFToken: '<!--{$CSRFToken}-->'},
                success: function(res) {
                    tagAndUpdate(res);
                }
            });
    	}
    	else {
    		tagAndUpdate(groupSel.selection);
    	}
    });
    dialog.show();
}

var dialog;
$(function() {
	dialog = new dialogController('xhrDialog', 'xhr', 'loadIndicator', 'button_save', 'button_cancelchange');
	dialog_simple = new dialogController('simplexhrDialog', 'simplexhr', 'simpleloadIndicator', 'simplebutton_save', 'simplebutton_cancelchange');

	$('#simpleloadIndicator').css({width: $(window).width() * .78, height: $(window).height() * .78});
	$('#simplexhr').css({width: $(window).width() * .8, height: $(window).height() * .8});
	
    getGroupList();
});

/* ]]> */
</script>