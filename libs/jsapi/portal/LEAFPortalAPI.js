/**
 * API for LEAF Request Portal
 */
var LEAFRequestPortalAPI = function () {
    var baseURL = './api/?a=',
        Forms = PortalFormsAPI(baseURL),
        Workflow = PortalWorkflowAPI(baseURL),

        /**
         * Get the base URL for the LEAF Portal API (e.g. "/LEAF_Request_Portal/api/?a=")
         * 
         * @return string   the base LEAF Portal API URL
         */
        getBaseURL = function () {
            return baseURL;
        },

        /**
         * Set the base URL for the LEAF Portal API (e.g. "/LEAF_Request_Portal/api/?a=")
         * 
         * @param urlBase string  base URL
         */
        setBaseURL = function (urlBase) {
            baseURL = urlBase;
            Forms.setBaseAPIURL(baseURL);
            Workflow.setBaseAPIURL(baseURL);
        };

    return {
        getBaseURL: getBaseURL,
        setBaseURL: setBaseURL,

        Forms: Forms,
        Workflow: Workflow
    };
};

/**
 * API for working with Forms
 *
 * @param baseAPIURL    string the base URL for the LEAF Portal API (e.g. "/LEAF_Request_Portal/api/?a=") 
 */
var PortalFormsAPI = function (baseAPIURL) {
    var apiBaseURL = baseAPIURL,
        apiURL = baseAPIURL + 'form',

        /**
         * Get the URL for the LEAF Portal Forms API
         */
        getAPIURL = function () {
            return apiURL;
        },

        /**
         * Get the base URL for the LEAF Portal API
         * 
         * @return string   the base LEAF Portal API URL used in this Forms API
         */
        getBaseAPIURL = function () {
            return apiBaseURL;
        },

        /**
         * Set the base URL for the LEAF Portal API
         * 
         * @param baseAPIURL string the base URL for the Portal API
         */
        setBaseAPIURL = function (baseAPIURL) {
            apiBaseURL = baseAPIURL;
            apiURL = baseAPIURL + 'form';
        },

        /**
         * Query a form using the Report Builder JSON syntax
         *
         * @param query     object              the JSON query object
         * @param onSuccess function(results)   callback containing the results object
         * @param onFail    function(error)     callback when query fails
         */
        query = function (query, onSuccess, onFail) {
            var fetchURL = apiURL + '/query/&q=' + JSON.stringify(query);

            $.ajax({
                method: 'GET',
                url: fetchURL,
                dataType: 'json'
            })
                .done(function (msg) {
                    onSuccess(msg);
                })
                .fail(function (err) {
                    onFail(err);
                });
            // .always(function() {});
        };

    return {
        getAPIURL: getAPIURL,
        getBaseAPIURL: getBaseAPIURL,
        setBaseAPIURL: setBaseAPIURL,
        query: query
    };
};

/**
 * API for working with Workflows
 * 
 * @param baseAPIURL string the base URL for the LEAF Portal API (e.g. "/LEAF_Request_Portal/api/?a=")
 */
var PortalWorkflowAPI = function (baseAPIURL) {
    var apiBaseURL = baseAPIURL,
        apiURL = baseAPIURL + 'workflow',

        // used for POST requests
        csrfToken = '',

        /**
         * Get the URL for the LEAF Portal Workflow API
         */
        getAPIURL = function () {
            return apiURL;
        },

        /**
         * Get the base URL for the LEAF Portal API
         * 
         * @return string   the base LEAF Portal API URL used in this Forms API
         */
        getBaseAPIURL = function () {
            return apiBaseURL;
        },

        /**
         * Set the base URL for the LEAF Portal API
         * 
         * @param baseAPIURL string the base URL for the Portal API
         */
        setBaseAPIURL = function (baseAPIURL) {
            apiBaseURL = baseAPIURL;
            apiURL = baseAPIURL + 'workflow';
        },

        setCSRFToken = function (token) {
            csrfToken = token;
        },

        /**
         * Set whether a Step in the specified Workflow requires a Digital Signature
         * 
         * @param workflowID            int                 the Workflow ID
         * @param stepID                int                 the Step ID
         * @param requiresSignature     boolean             whether a Digital Signature is required
         * @param onSuccess             function(result)    callback when operation succeeds
         * @param onFail                function(error)     callback when operation fails
         */
        setStepSignatureRequirement = function (workflowID, stepID, requiresSignature, onSuccess, onFail) {
            $.ajax({
                method: 'POST',
                url: apiURL + '/' + workflowID + '/step/' + stepID + '/requiresig',
                dataType: "text",
                data: { "requiresSig": requiresSignature, CSRFToken: csrfToken}
            })
                .done(function (msg) {
                    onSuccess(msg);
                })
                .fail(function (err) {
                    onFail(err);
                });
        };

    return {
        getAPIURL: getAPIURL,
        getBaseAPIURL: getBaseAPIURL,
        setBaseAPIURL: setBaseAPIURL,
        setCSRFToken: setCSRFToken,
        setStepSignatureRequirement: setStepSignatureRequirement
    };
};