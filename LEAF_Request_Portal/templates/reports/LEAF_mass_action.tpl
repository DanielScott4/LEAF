<style>
    div#massActionContainer {
        width: 800px;
        margin: auto;
    }
    #filterContainer, #searchRequestsContainer, #searchResults, #errorMessage, #iconBusy {
        display: none;
    }
    #filterContainer, #actionContainer {
        padding-bottom: 5px;
    }
    #iconBusy{
        height: 20px;
    }
    table#requests {
        border-collapse: collapse;
    }
    table#requests th {
        text-align: center;
        border: 1px solid black;
        padding: 4px 2px;
        font-size: 12px;
        background-color: rgb(209, 223, 255);
    }
    table#requests td {
        border: 1px solid black; 
        padding: 8px; 
        font-size: 12px;
    }
    #searchBar {
        display: inline-flex;
        padding-bottom: 16px;
        text-align: center;
        width: 95%;
    }
    #searchBar input {
        height: 35px;
        width: 95%;
        font-size: large;
    }
    #searchBar .searchIcon {
        margin-left: 8px;
        margin-top: 8px;
        cursor: pointer;
        height: 25px;
        width: 25px;
    }
</style>
<!--{include file="site_elements/generic_confirm_xhrDialog.tpl"}-->
<script>

var processedRequests = 0;
var totalActions = 0;
var actionValue = '';
var filterValue = '';
var successfulActionRecordIDs = [];
var failedActionRecordIDs = [];
var dialog_confirm;

$(document).ready(function(){

    chooseAction();
    dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');

    $('select#action').change(function(){
        chooseAction();
    });

    $('select#filter').change(function(){
        doSearch();
    });

    $("#searchRequestsInput").keyup(function() {
        if (event.keyCode !== 9 && event.keyCode !== 16) {//don't search when entering with tab, or shift-tab
            doSearch();
        }
    });

    $("button.takeAction").click(function() {
        dialog_confirm.setContent('<img src="../../../libs/dynicons/?img=process-stop.svg&amp;w=48" alt="Cancel Request" style="float: left; padding-right: 24px" /> Are you sure you want to perform this action?');

        dialog_confirm.setSaveHandler(function() {
            executeMassAction();
            dialog_confirm.hide();
        });
        dialog_confirm.show();
    });

    $('input#selectAllRequests').change(function(){
        $('input.massActionRequest').prop('checked', $(this).is(':checked'));
    });

    $(document).on('change', 'input.massActionRequest', function() { 
        $('input#selectAllRequests').prop('checked', false);
    });
});

function chooseAction()
{
    setUpFilterSelector();
    if($('select#action').val() !== '')
    {
        $('#searchRequestsContainer').show();
        doSearch();
    }
    else
    {
        $('#searchRequestsContainer').hide();
        $('#searchResults').hide();
        $('#errorMessage').hide();
        
    }
}

/**
 * When an action is selected, the filter dropdown must be refreshed. 
 * This sets the options based on the action chosen.
 */
function setUpFilterSelector()
{
    //clear old options
    $('select#filter option').remove();

    switch($('select#action').val()) {
        case 'cancel':
            $('select#filter').append('<option value="">-Select-</option>');
            $('select#filter').append('<option value="unsubmitted">unsubmitted</option>');
            $('select#filter').append('<option value="submitted">submitted</option>');
            $('select#filter').append('<option value="submitted-incomplete">submitted and incomplete</option>');
            $('select#filter').append('<option value="submitted-complete">submitted and complete</option>');
            $('#filterContainer').show();
            break;
        case 'restore':
            $('select#filter').append('<option value="">-Select-</option>');
            $('select#filter').append('<option value="unsubmitted">unsubmitted</option>');
            $('select#filter').append('<option value="submitted">submitted</option>');
            $('#filterContainer').show();
            break;
        default:
            $('#filterContainer').hide();
    }
}

/**
 * Sets the selected action, filter, and search string to gloabal variables
 */
function lockInSelections()
{
    actionValue = $('select#action').val();
    filterValue = $('select#filter').val();
    titleSearchString = $('#searchRequestsInput').val();
}

/**
 * Sets up and builds the search query, passing it along to listRequests
 */
function doSearch()
{
    var getCancelled = '';
    var getSubmitted = '';
    var getResolved = '';

    var filterGetSubmitted = '';
    var filterGetResolved = '';
    $('input#selectAllRequests').prop('checked', false);
    setProgress("");
    lockInSelections();

    switch(filterValue) {
        case 'unsubmitted':
            filterGetSubmitted = 'false';
            break;
        case 'submitted':
            filterGetSubmitted = 'true';
            break;
        case 'submitted-incomplete':
            filterGetSubmitted = 'true';
            filterGetResolved = 'false';
            break;
        case 'submitted-complete':
            filterGetSubmitted = 'true';
            filterGetResolved = 'true';
            break;
    }

    switch(actionValue) {
        case 'submit':
            getCancelled = 'false';
            getSubmitted = 'false';
            getResolved = '';
            break;
        case 'cancel':
            getCancelled = 'false';
            getSubmitted = filterGetSubmitted;
            getResolved = filterGetResolved;
            break;
        case 'restore':
            getCancelled = 'true';
            getSubmitted = filterGetSubmitted;
            getResolved = '';
            break;
    }
    var queryObj = buildQuery(titleSearchString, getCancelled, getSubmitted, getResolved);
    listRequests(queryObj);
}

/**
 * Builds query object to pass to form/query
 *
 * @param {string}  [titleFilterString] String to compare requests titles to in search.
 * @param {string}  [getCancelled]      '','true', or 'false' whether to filter by cancelled, then whether request is('true') or isn't('false') cancelled 
 * @param {string}  [getSubmitted]      '','true', or 'false' whether to filter by submitted, then whether request is('true') or isn't('false') cancelled 
 * @param {string}  [getResolved]       '','true', or 'false' whether to filter by resolved, then whether request is('true') or isn't('false') cancelled 
 * 
 * @return {Object} query object to pass to form/query.
 */
function buildQuery(titleFilterString, getCancelled, getSubmitted, getResolved)
{
    var requestQuery = {"terms":[],
                        "joins":["service", "recordsDependencies", "categoryName", "status"],
                        "sort":{}
                        };
    

    if(titleFilterString.trim())
    {
        requestQuery.terms.push({"id":"title","operator":"LIKE","match":"*"+titleFilterString.trim()+"*"});
    }

    if(getCancelled === 'true')
    {
        requestQuery.terms.push({"id":"stepID","operator":"=","match":"deleted"});
    }
    else if(getCancelled === 'false')
    {
        requestQuery.terms.push({"id":"stepID","operator":"!=","match":"deleted"});
    }

    if(getSubmitted === 'true')
    {
        requestQuery.terms.push({"id":"stepID","operator":"=","match":"submitted"});
    }
    else if(getSubmitted === 'false')
    {
        requestQuery.terms.push({"id":"stepID","operator":"!=","match":"submitted"});
    }

    //when filtering by resolved (either = or !=), 
    //form/query also makes sure that: requests ARE submitted and AREN'T cancelled
    //so, here we make sure that these are already the case
    if(getResolved === 'true' && getSubmitted === 'true' && getCancelled === 'false')
    {
        requestQuery.terms.push({"id":"stepID","operator":"=","match":"resolved"});
    }
    else if(getResolved === 'false' && getSubmitted === 'true' && getCancelled === 'false')
    {
        requestQuery.terms.push({"id":"stepID","operator":"!=","match":"resolved"});
    }
    return requestQuery;
}

/**
 * Looks up requests based on filter/searchbar and builds table with the results
 *
 * @param {Object}  [queryObj]  Object to pass to form/query
 */
function listRequests(queryObj)
{
    $('#searchResults').hide();
    $('#errorMessage').hide();
    $('table#requests tr.requestRow').remove();
    $('#iconBusy').show();

    $.ajax({
        type: 'GET',
        url: './api/?a=form/query',
        data: {q: JSON.stringify(queryObj),
                CSRFToken: '<!--{$CSRFToken}-->'},
        cache: false
    }).done(function(data) {
        if(Object.keys(data).length)
        {
            $.each(data, function( index, value ) {
                requestsRow = '<tr class="requestRow">';
                requestsRow += '<td><a href="index.php?a=printview&amp;recordID='+value.recordID+'">'+value.recordID+'</a></td>';
                requestsRow += '<td>'+value.categoryNames[0]+'</td>';
                requestsRow += '<td>'+(value.service == null ? '' : value.service)+'</td>';
                requestsRow += '<td>'+value.title+'</td>';
                requestsRow += '<td><input type="checkbox" name="massActionRequest" class="massActionRequest" value="'+value.recordID+'"></td>';
                requestsRow += '</tr>';
                $('table#requests').append(requestsRow);
            });
            $('#searchResults').show();
        }
        else
        {
            $('#errorMessage').html('No Results');
            $('#errorMessage').show();
        }
    }).fail(function (jqXHR, error, errorThrown) {
        console.log(jqXHR);
        console.log(error);
        console.log(errorThrown);
    }).always(function (){
        $('#iconBusy').hide();
    });
}

/**
 * Executes the selected action on each request selected in the table
 */
function executeMassAction()
{
    var selectedRequests = $('input.massActionRequest:checked');
    processedRequests = 0;
    totalActions = selectedRequests.length;
    successfulActionRecordIDs = [];
    failedActionRecordIDs = [];
    
    if(totalActions)
    {
        $('button.takeAction').attr("disabled", "disabled");
    }
    $.each(selectedRequests, function(key, item) {
        var ajaxPath = '';
        var ajaxData = {};
        var recordID = $(item).val();
        switch(actionValue) {    
            case 'submit':
                ajaxPath = './api/?a=form/'+recordID+'/submit';
                ajaxData = {CSRFToken: '<!--{$CSRFToken}-->'};
                break;
            case 'cancel':
                ajaxPath = './api/?a=form/'+recordID+'/cancel';
                ajaxData = {CSRFToken: '<!--{$CSRFToken}-->'};
                break;
            case 'restore':
                ajaxPath = './ajaxIndex.php?a=restore';
                ajaxData = {restore: recordID,
                            CSRFToken: '<!--{$CSRFToken}-->'};
                break;
        }

        executeOneAction(recordID, ajaxPath, ajaxData);
	});
}

/**
 * Executes one ajax call to execute an action
 *
 * @param {int}     [recordID]  recordID for the record that the selected action is being applied to
 * @param {string}  [ajaxPath]  the api path for the selected action
 * @param {Object}  [ajaxData]  data object to pass to the selected ajaxPath
 */
function executeOneAction(recordID, ajaxPath, ajaxData)
{
    $.ajax({
        type: 'POST',
        url: ajaxPath,
        data: ajaxData,
        dataType: "text",
        cache: false
    }).done(function(data) {
        successTrueFalse = true;
        updateProgress(recordID, successTrueFalse);
    }).fail(function (jqXHR, error, errorThrown) {
        successTrueFalse = false;
        updateProgress(recordID, successTrueFalse);
        console.log(jqXHR);
        console.log(error);
        console.log(errorThrown);
    });
}

/**
 * Updates progress message, checks if the process is complete, and sets complete message
 *
 * @param {int}     [recordID]  recordID for the record that the selected action is being applied to
 * @param {boolean} [success]   true if the update is marking a success, false if a failure
 */
function updateProgress(recordID, success)
{
    if(success)
    {
        successfulActionRecordIDs.push(recordID);
    }
    else
    {
        failedActionRecordIDs.push(recordID);
    }
    processedRequests++;
    setProgress("Completed: " + processedRequests + '/' + totalActions);
    if(processedRequests === totalActions)
    {
        if(failedActionRecordIDs.length > 0)
        {
            var alertMessage = "Action failed on the following requests:";
            $.each(failedActionRecordIDs, function(key, item) {
                alertMessage += "\n - ID: " + item;
            });
            alert(alertMessage);
        }

        doSearch();
        setProgress(successfulActionRecordIDs.length + ' successes and ' + failedActionRecordIDs.length + ' failures of ' + totalActions + ' total.');
        
        $('button.takeAction').removeAttr("disabled");
    }
}

/**
 * Updates progress message
 *
 * @param {string}  [message]   String to set into the progress area
 */
function setProgress(message)
{
    $('div.progress').html(message);
}
</script>
<div id="massActionContainer">
    <h1>Mass Action</h1>
    <div id="actionContainer">
        <label for="action"> Choose Action </label>
        <select id="action" name="action">  
            <option value="">-Select-</option>
            <option value="cancel">Cancel</option>
            <option value="restore">Restore</option>
            <option value="submit">Submit</option>
        </select>
    </div>

    <div id="filterContainer">
        <label for="filter"> Show Only </label>
        <select id="filter" name="filter"></select>
    </div>

    <div id="searchRequestsContainer">
        <div id="searchBar">
            <img class="searchIcon" src="../libs/dynicons/?img=search.svg&amp;w=16" alt="search icon">&nbsp;
            <input id="searchRequestsInput" type="text" placeholder="Search by Title of Request">
        </div>
    </div>
    <img id="iconBusy" src="./images/indicator.gif" class="employeeSelectorIcon" alt="busy">
    <div id="searchResults">
        <button class="buttonNorm takeAction" style="text-align: center; font-weight: bold; white-space: normal">Take Action</button>
        <div class="progress"></div>
        <table id="requests">
            <tr id="headerRow">
                <th>UID</th>
                <th>Type</th>
                <th>Service</th>
                <th>Title</th>
                <th><input type="checkbox" name="selectAllRequests" id="selectAllRequests" value=""></th>
            </tr>
        </table>
        <button class="buttonNorm takeAction" style="text-align: center; font-weight: bold; white-space: normal">Take Action</button>
    </div>
    <div class="progress"></div>
    <div id="errorMessage"></div>
</div>