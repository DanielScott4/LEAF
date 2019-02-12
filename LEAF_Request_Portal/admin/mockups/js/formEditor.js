var section_defaults = {
	title: "+ Add Section",
	isNew: true,
	description: "",
	questions: [],
	rawQuestions: []
};

var question_defaults = {
	text: "+ Add Question",
	inputType: "",
	defaultAnswer: "",
	required: false,
	sensitive: false,
	isNew: true
};

var question_test = {
	text: "Question Text1",
	inputType: "text",
	template: '',
	defaultAnswer: "",
	required: false,
	sensitive: false,
	isNew: false
};

var question_test2 = {
	text: "Request Format",
	inputType: "radio",
	template: '<fieldset>' +
		'<input type="radio" id="option-1" name="request_format" value="photography" checked>' +
		'<label for="option-1">Photography</label>' +
		'<input type="radio" id="option-2" name="request_format" value="sharepoint site request">' +
		'<label for="option-2">Sharepoint Site Request</label>' +
		'<input type="radio" id="option-3" name="request_format" value="intranet site">' +
		'<label for="option-3">Intranet Site</label>' +
		'</fieldset>'
	,
	defaultAnswer: "",
	required: false,
	sensitive: false,
	isNew: false
};

var question_test3 = {
	text: "Question Text3",
	inputType: "text",
	template: '<input type="text"/>'
	,
	defaultAnswer: "",
	required: false,
	sensitive: false,
	isNew: false
};
var mockData = [
	{
		id: "someHash",
		title: "Nature of Action Request",
		type: "section-card",
		isNew: false,
		description: "Select the type of request:",
		questions: [],
		rawQuestions: [question_test, question_test2, question_test3, question_defaults]
	},
	section_defaults
];
var test = {
	title: "test title",
	description: "test description",
	editFormOpen: false,
	questions: [],
	rawQuestions: []
};

var test2 = {
	title: "test title",
	description: "test description",
	editFormOpen: true,
	questions: [],
	rawQuestions: []
};

var state = {
	sections: [test, test2]
};


var vm = new Vue({
	el: ".leaf-app",
	data: function () {
		return {
			sections: mockData
		}
	}
});
