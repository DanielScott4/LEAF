INSERT INTO `actions`
(`actionType`, `actionText`, `actionTextPasttense`, `actionIcon`, `actionAlignment`, `sort`, `fillDependency`) VALUES
('Test Action Type 1', 'Test Action Text 1', 'Test Action Past Tense 1', 'go-next.svg', 'right', 0, 1),
('Test Action Type 2', 'Test Action Text 2', 'Test Action Past Tense 2', 'software-update-urgent.svg', 'left', 0, -2),
('Test Action Type 3', 'Test Action Text 3', 'Test Action Past Tense 3', 'edit-undo.svg', 'left', 0, 0),
('Test Action Type 4', 'Test Action Text 4', 'Test Action Past Tense 4', 'process-stop.svg', 'right', 0, -1);

INSERT INTO `categories`
(`categoryID`, `parentID`, `categoryName`, `categoryDescription`, `workflowID`, `sort`) VALUES
('Test Form 1', '', 'Test Form Name 1', 'Test Form Description 1', 1, 0),
('Test Form 2', '', 'Test Form Name 2', 'Test Form Description 2', 1, 0);

INSERT INTO `category_count`
(`recordID`, `categoryID`, `count`) VALUES
(1, 'Test Form 1', 1),
(2, 'Test Form 1', 1),
(3, 'Test Form 2', 1),
(4, 'Test Form 2', 1);

INSERT INTO `data`
(`recordID`, `indicatorID`, `series`, `data`, `timestamp`, `userID`) VALUES
(2, 1, 1, 'Test Data 1', 0, 1);

INSERT INTO `notes`
(`recordID`, `note`, `timestamp`, `userID`, `deleted`) VALUES
(2, 'Test Note 1', 0, 'tester', NULL),
(2, 'Test Note 2', 0, 'tester', NULL);

INSERT INTO `records`
(`date`, `serviceID`, `userID`, `title`, `priority`, `lastStatus`, `submitted`, `deleted`, `isWritableUser`, `isWritableGroup`) VALUES
(0, 0, 'tester', 'Test Request Title 1', 0, NULL, 0, 0, 1, 1),
(0, 0, 'tester', 'Test Request Title 2', 0, NULL, 0, 0, 1, 1),
(0, 0, 'tester', 'Test Request Title 3', 0, NULL, 0, 0, 1, 1),
(0, 0, 'tester', 'Test Request Title 4', 0, NULL, 0, 0, 1, 1);

INSERT INTO `dependencies`
(`description`) VALUES
('Description 1'),
('Description 2');

INSERT INTO `records_dependencies`
(`recordID`, `dependencyID`, `filled`, `time`) VALUES
(1, 1, 0, NULL),
(2, 1, 0, NULL),
(3, 1, 1, NULL);

INSERT INTO `workflows`
(`initialStepID`, `description`) VALUES
(1, 'Test Workflow Description 1'),
(1, 'Test Workflow Description 2');

INSERT INTO `workflow_steps`
(`workflowID`, `stepTitle`, `stepBgColor`, `stepFontColor`, `stepBorder`, `jsSrc`, `posX`, `posY`) VALUES
(10, 'Test Step Title 1', '#fffdcd', 'black', '1px solid black', '', 100, 100),
(10, 'Test Step Title 2', '#fffdcd', 'black', '1px solid black', '', 300, 100),
(10, 'Test Step Title 3', '#fffdcd', 'black', '1px solid black', '', 500, 100),
(11, 'Test Step Title 4', '#fffdcd', 'black', '1px solid black', '', 100, 100),
(11, 'Test Step Title 5', '#fffdcd', 'black', '1px solid black', '', 300, 100),
(11, 'Test Step Title 6', '#fffdcd', 'black', '1px solid black', '', 500, 100);

INSERT INTO `step_dependencies`
(`stepID`, `dependencyID`) VALUES
(14, 15);

INSERT INTO `workflow_routes`
(`workflowID`, `stepID`, `nextStepID`, `actionType`, `displayConditional`) VALUES
(10, 14, 2, 'approve', ''),
(10, 14, 3, 'concur', ''),
(10, 14, 0, 'submit', ''),
(11, 14, 5, 'Test Action Type 1', ''),
(11, 14, 6, 'Test Action Type 2', ''),
(11, 14, 0, 'Test Action Type 3', '');

