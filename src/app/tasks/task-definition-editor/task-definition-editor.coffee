angular.module('doubtfire.tasks.task-definition-editor', [])

#
# Allows the creation and modification of task definitions
#
.directive('taskDefinitionEditor', ->
  replace: true
  restrict: 'E'
  templateUrl: 'tasks/task-definition-editor/task-definition-editor.tpl.html'
  scope:
    unit: "="
    task: "="
    isNew: "="
  controller: ($scope, $filter, DoubtfireConstants, taskService, gradeService, TaskDefinition, alertService, Unit, Task, ProgressModal, TaskSubmission, fileDownloaderService) ->
    $scope.overseer_enabled = DoubtfireConstants.IsOverseerEnabled

    $scope.grades = gradeService.grades

    $scope.targetPicker = { open: false }
    $scope.duePicker = { open: false }
    $scope.startPicker = { open: false }

    # Get docker images available for automated task assessment for the unit.
    TaskSubmission.getDockerImagesAsPromise().then (images) ->
      $scope.dockerImages = images

    # Get the confugurable, external name of Doubtfire
    $scope.externalName = DoubtfireConstants.ExternalName

    #
    # Active task tab group
    #
    $scope.taskAdmin =
      tabsData:
        taskSheet:
          title: "Task Description"
          subtitle: "Provide the descriptive details for this task"
          icon: "fa-info"
          seq: 0
          active: false
        rareSettings:
          title: "Other Settings"
          subtitle: "Adjust settings to customise task interaction"
          icon: "fa-adjust"
          seq: 1
          active: false
        fileUpload:
          title: "Submission Details"
          subtitle: "Indicate what files students need to submit for this task"
          icon: "fa-upload"
          seq: 2
          active: false
        taskResources:
          title: "Task Resources"
          subtitle: "Upload the task sheet and other resources for this task"
          icon: "fa-file-o"
          seq: 3
          active: false
        plagiarismChecks:
          title: "Plagiarism Detection"
          subtitle: "Add plagiarism checks for this task"
          icon: "fa-eye"
          seq: 4
          active: false

    if $scope.overseer_enabled.value
      $scope.taskAdmin.tabsData.taskAssessmentResources = {
        title: "Task Assessment Resources"
        subtitle: "Upload the bash script and other resources for this task assessment"
        icon: "fa-wpforms"
        seq: 5
        active: false}

    #
    # The task sheet uploader...
    #
    $scope.taskSheet = { file: { name: 'Task Sheet', type: 'document'  } }
    $scope.taskSheetUploadUrl = -> Unit.taskSheetUploadUrl($scope.unit, $scope.task)

    $scope.onTaskSheetSuccess = (response) ->
      alertService.add("success", "Task sheet uploaded", 2000)
      $scope.task.has_task_sheet = true
      # $scope.filesUploaded = response

    # Assign task the stream - this is called
    # From the template as you can't ngModel
    # With dropdown
    $scope.changeTaskStream = (task, stream) ->
      task.tutorial_stream = stream

    $scope.downloadTaskPDFUrl = ->
      fileDownloaderService.downloadFile("#{Task.getTaskPDFUrl($scope.unit, $scope.task)}&as_attachment=true", "#{$scope.task.abbreviation}-task-sheet.pdf")

    $scope.downloadTaskResources = ->
      fileDownloaderService.downloadFile("#{Task.getTaskResourcesUrl($scope.unit, $scope.task)}&as_attachment=true", "#{$scope.task.abbreviation}-task-sheet.pdf")

    $scope.removeTaskSheet = (task) ->
      TaskDefinition.taskSheet.delete { unit_id: $scope.unit.id, task_def_id: task.id},
        (success) ->
          task.has_task_sheet = false
          alertService.add("success", "Deleted task sheet", 2000)
        (error) ->
          alertService.add("danger", "Delete failed, #{error.data?.message}", 6000)

    $scope.removeTaskResources = (task) ->
      TaskDefinition.taskResources.delete { unit_id: $scope.unit.id, task_def_id: task.id},
        (success) ->
          task.has_task_resources = false
          alertService.add("success", "Deleted task resources", 2000)
        (error) ->
          alertService.add("danger", "Delete failed, #{error.data?.message}", 6000)

    $scope.removeTaskAssessmentResources = (task) ->
      TaskDefinition.taskAssessmentResources.delete { unit_id: $scope.unit.id, task_def_id: task.id},
        (success) ->
          task.has_task_assessment_resources = false
          alertService.add("success", "Deleted task assessment resources", 2000)
        (error) ->
          alertService.add("danger", "Delete failed, #{error.data?.message}", 6000)

    # $scope.removeTaskAssessmentTests = (task) ->
    #   TaskDefinition.taskAssessmentTests.delete { unit_id: $scope.unit.id, task_def_id: task.id},
    #     (success) ->
    #       task.has_task_assessment_tests = false
    #       alertService.add("success", "Deleted task assessment tests", 2000)
    #     (error) ->
    #       alertService.add("danger", "Delete failed, #{error.data?.message}", 6000)

    #
    # The task resources uploader...
    #
    $scope.taskResources = { file: { name: 'Task Resources', type: 'zip' } }
    $scope.taskResourcesUploadUrl = -> Unit.taskResourcesUploadUrl($scope.unit, $scope.task)

    $scope.onTaskResourcesSuccess = (response) ->
      alertService.add("success", "Task sheet uploaded", 2000)
      $scope.task.has_task_resources = true

    $scope.resourceUrl = ->
      Task.getTaskResourcesUrl($scope.unit, $scope.task)


    # #
    # # The assessment resources uploader...
    # #
    $scope.taskAssessmentResources = { file: { name: 'Task Assessment Resources', type: 'zip' } }
    $scope.taskAssessmentResourcesUploadUrl = -> Unit.taskAssessmentResourcesUploadUrl($scope.unit, $scope.task)

    $scope.onTaskAssessmentResourcesSuccess = (response) ->
      alertService.add("success", "Task assessment resources uploaded", 2000)
      $scope.task.has_task_assessment_resources = true

    $scope.downloadTaskAssessmentResources = ->
      fileDownloaderService.downloadFile(Task.getTaskAssessmentResourcesUrl($scope.unit, $scope.task), "#{$scope.unit.code}-#{$scope.task.abbreviation}-task-assessment-resources.zip")

    # #
    # # The assessment tests uploader...
    # #
    # $scope.taskAssessmentTests = { file: { name: 'Task Assessment Resources', type: 'zip' } }
    # $scope.taskAssessmentTestsUploadUrl = -> Unit.taskAssessmentResourcesUploadUrl($scope.unit, $scope.task)

    # $scope.onTaskAssessmentTestsSuccess = (response) ->
    #   alertService.add("success", "Task assessment tests uploaded", 2000)
    #   $scope.task.has_task_assessment_tests = true

    # $scope.taskAssessmentTestsUrl = ->
    #   Task.getTaskAssessmentTestsUrl($scope.unit, $scope.task)


    #
    # Sets the active tab
    #
    $scope.setActiveTab = (tab) ->
      # Do nothing if we're switching to the same tab
      return if tab is $scope.activeTab
      if $scope.activeTab?
        $scope.activeTab.active = false
      $scope.activeTab = tab
      $scope.activeTab.active = true

    #
    # Checks if tab is the active tab
    #
    $scope.isActiveTab = (tab) ->
      tab is $scope.activeTab

    $scope.setActiveTab($scope.taskAdmin.tabsData['taskSheet'])

    # Datepicker opener
    $scope.open = ($event, pickerData) ->
      $event.preventDefault()
      $event.stopPropagation()

      unless pickerData.open
        # Close both
        $scope.targetPicker.open = false
        $scope.duePicker.open = false
        $scope.startPicker.open = false

      # Toggle one
      pickerData.open = ! pickerData.open

    $scope.addUpReq = ->
      newLength = $scope.task.upload_requirements.length + 1
      newUpReq = { key: "file#{newLength-1}", name: "", type: "code", language: "Pascal" }
      $scope.task.upload_requirements.push newUpReq

    $scope.removeUpReq = (upReq) ->
      $scope.task.upload_requirements = $scope.task.upload_requirements.filter (anUpReq) -> anUpReq.key isnt upReq.key

    $scope.addCheck = ->
      newLength = $scope.task.plagiarism_checks.length + 1
      newCheck = { key: "check#{newLength-1}", pattern: "", type: "" }
      $scope.task.plagiarism_checks.push newCheck

    $scope.removeCheck = (check) ->
      $scope.task.plagiarism_checks = $scope.task.plagiarism_checks.filter (aCheck) -> aCheck.key isnt check.key

    $scope.allowedQualityPoints = [0..10]

    populate_task = (oldTask, newTask) ->
      _.extend(oldTask, newTask)
      if newTask.weighting
        oldTask.weight = newTask.weighting

    $scope.deleteTask = ->
      taskService.deleteTask $scope.task, $scope.unit, null

    $scope.saveTask = ->
      # Map the task to upload to the appropriate fields
      task = {}
      _.extend(task, $scope.task)

      task.weighting = $scope.task.weight
      task.upload_requirements = JSON.stringify $scope.task.upload_requirements
      task.plagiarism_checks = JSON.stringify $scope.task.plagiarism_checks
      task.tutorial_stream_abbr = $scope.task.tutorial_stream
      if task.group_set
        task.group_set_id = task.group_set.id
      else
        task.group_set_id = -1

      if (Date.parse(task.start_date) > Date.parse(task.target_date)) || (Date.parse(task.target_date) > Date.parse(task.due_date))
        alertService.add("danger", "Invalid task dates, unit not saved. Ensure start date is before due date, and due date is before deadline.", 5000)
      else
        if task.target_date && task.target_date.getMonth
          tgt = task.target_date
          task.target_date = "#{tgt.getFullYear()}-#{tgt.getMonth() + 1}-#{tgt.getDate()}"

        if task.start_date && task.start_date.getMonth
          tgt = task.start_date
          task.start_date = "#{tgt.getFullYear()}-#{tgt.getMonth() + 1}-#{tgt.getDate()}"

        if task.due_date && task.due_date.getMonth
          due = task.due_date
          task.due_date = "#{due.getFullYear()}-#{due.getMonth() + 1}-#{due.getDate()}"

        if $scope.isNew
          promise = TaskDefinition.create( { unit_id: $scope.unit.id, task_def: task } ).$promise
          ProgressModal.show('Task Definition Creation', 'Please wait while student projects are updated.', promise)
          promise.then (
            (response) ->
              $scope.unit.task_definitions.push(response)
              alertService.add("success", "#{response.name} Added", 2000)
          ),
          (
            (response) ->
              if response.data.error?
                alertService.add("danger", "Error: " + response.data.error, 6000)
          )
        else
          TaskDefinition.update( { unit_id: $scope.unit.id, id: task.id, task_def: task } ).$promise.then (
            (response) ->
              populate_task($scope.task, response)
              alertService.add("success", "#{response.name} Updated", 2000)
          ),
          (
            (response) ->
              if response.data.error?
                alertService.add("danger", "Error: " + response.data.error, 6000)
          )
)
