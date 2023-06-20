public type AbortQueuedMigrationsInput record {
    string? clientMutationId?;
    string ownerId?;
};

public type AcceptEnterpriseAdministratorInvitationInput record {
    string? clientMutationId?;
    string invitationId?;
};

public type AcceptTopicSuggestionInput record {
    string? clientMutationId?;
    string name?;
    string repositoryId?;
};

public type AddAssigneesToAssignableInput record {
    string? clientMutationId?;
    string assignableId?;
    string[] assigneeIds?;
};

public type AddCommentInput record {
    string? clientMutationId?;
    string body?;
    string subjectId?;
};

public type AddDiscussionCommentInput record {
    string? clientMutationId?;
    string discussionId?;
    string? replyToId?;
    string body?;
};

public type AddDiscussionPollVoteInput record {
    string? clientMutationId?;
    string pollOptionId?;
};

public type AddEnterpriseOrganizationMemberInput record {
    string organizationId?;
    string? role?;
    string? clientMutationId?;
    string[] userIds?;
    string enterpriseId?;
};

public type AddEnterpriseSupportEntitlementInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type AddLabelsToLabelableInput record {
    string[] labelIds?;
    string? clientMutationId?;
    string labelableId?;
};

public type AddProjectCardInput record {
    string? note?;
    string? clientMutationId?;
    string? contentId?;
    string projectColumnId?;
};

public type AddProjectColumnInput record {
    string? clientMutationId?;
    string name?;
    string projectId?;
};

public type AddProjectV2DraftIssueInput record {
    string? clientMutationId?;
    string? body?;
    string title?;
    string[]? assigneeIds?;
    string projectId?;
};

public type AddProjectV2ItemByIdInput record {
    string? clientMutationId?;
    string contentId?;
    string projectId?;
};

public type AddPullRequestReviewCommentInput record {
    string? path?;
    string? pullRequestReviewId?;
    string? clientMutationId?;
    string? inReplyTo?;
    int? position?;
    string? body?;
    string? pullRequestId?;
    anydata? commitOID?;
};

public type AddPullRequestReviewInput record {
    DraftPullRequestReviewComment?[]? comments?;
    string? clientMutationId?;
    DraftPullRequestReviewThread?[]? threads?;
    string? body?;
    string? event?;
    string pullRequestId?;
    anydata? commitOID?;
};

public type AddPullRequestReviewThreadInput record {
    string path?;
    string? pullRequestReviewId?;
    string? side?;
    string? clientMutationId?;
    int? line?;
    int? startLine?;
    string body?;
    string? pullRequestId?;
    string? startSide?;
    string? subjectType?;
};

public type AddReactionInput record {
    string? clientMutationId?;
    string content?;
    string subjectId?;
};

public type AddStarInput record {
    string? clientMutationId?;
    string starrableId?;
};

public type AddUpvoteInput record {
    string? clientMutationId?;
    string subjectId?;
};

public type AddVerifiableDomainInput record {
    string? clientMutationId?;
    anydata domain?;
    string ownerId?;
};

public type ApproveDeploymentsInput record {
    string? clientMutationId?;
    string[] environmentIds?;
    string? comment?;
    string workflowRunId?;
};

public type ApproveVerifiableDomainInput record {
    string? clientMutationId?;
    string id?;
};

public type ArchiveProjectV2ItemInput record {
    string itemId?;
    string? clientMutationId?;
    string projectId?;
};

public type ArchiveRepositoryInput record {
    string? clientMutationId?;
    string repositoryId?;
};

public type AuditLogOrder record {
    string? 'field?;
    string? direction?;
};

public type BranchNamePatternParametersInput record {
    boolean? negate?;
    string? name?;
    string pattern?;
    string operator?;
};

public type BulkSponsorship record {
    int amount?;
    string? sponsorableLogin?;
    string? sponsorableId?;
};

public type CancelEnterpriseAdminInvitationInput record {
    string? clientMutationId?;
    string invitationId?;
};

public type CancelSponsorshipInput record {
    string? sponsorableLogin?;
    string? clientMutationId?;
    string? sponsorId?;
    string? sponsorLogin?;
    string? sponsorableId?;
};

public type ChangeUserStatusInput record {
    boolean? limitedAvailability?;
    string? organizationId?;
    string? emoji?;
    string? clientMutationId?;
    string? message?;
    anydata? expiresAt?;
};

public type CheckAnnotationData record {
    string path?;
    string? rawDetails?;
    string annotationLevel?;
    CheckAnnotationRange location?;
    string message?;
    string? title?;
};

public type CheckAnnotationRange record {
    int endLine?;
    int? endColumn?;
    int? startColumn?;
    int startLine?;
};

public type CheckRunAction record {
    string identifier?;
    string description?;
    string label?;
};

public type CheckRunFilter record {
    string? checkType?;
    int? appId?;
    string[]? conclusions?;
    string[]? statuses?;
    string? checkName?;
    string? status?;
};

public type CheckRunOutput record {
    string summary?;
    CheckRunOutputImage[]? images?;
    CheckAnnotationData[]? annotations?;
    string? text?;
    string title?;
};

public type CheckRunOutputImage record {
    anydata imageUrl?;
    string alt?;
    string? caption?;
};

public type CheckSuiteAutoTriggerPreference record {
    string appId?;
    boolean setting?;
};

public type CheckSuiteFilter record {
    int? appId?;
    string? checkName?;
};

public type ClearLabelsFromLabelableInput record {
    string? clientMutationId?;
    string labelableId?;
};

public type ClearProjectV2ItemFieldValueInput record {
    string itemId?;
    string? clientMutationId?;
    string projectId?;
    string fieldId?;
};

public type CloneProjectInput record {
    boolean? 'public?;
    string sourceId?;
    boolean includeWorkflows?;
    string? clientMutationId?;
    string name?;
    string targetOwnerId?;
    string? body?;
};

public type CloneTemplateRepositoryInput record {
    string visibility?;
    string? clientMutationId?;
    boolean? includeAllBranches?;
    string name?;
    string repositoryId?;
    string? description?;
    string ownerId?;
};

public type CloseDiscussionInput record {
    string? reason?;
    string? clientMutationId?;
    string discussionId?;
};

public type CloseIssueInput record {
    string issueId?;
    string? clientMutationId?;
    string? stateReason?;
};

public type ClosePullRequestInput record {
    string? clientMutationId?;
    string pullRequestId?;
};

public type CommitAuthor record {
    string[]? emails?;
    string? id?;
};

public type CommitAuthorEmailPatternParametersInput record {
    boolean? negate?;
    string? name?;
    string pattern?;
    string operator?;
};

public type CommitContributionOrder record {
    string 'field?;
    string direction?;
};

public type CommitMessage record {
    string? body?;
    string headline?;
};

public type CommitMessagePatternParametersInput record {
    boolean? negate?;
    string? name?;
    string pattern?;
    string operator?;
};

public type CommittableBranch record {
    string? repositoryNameWithOwner?;
    string? branchName?;
    string? id?;
};

public type CommitterEmailPatternParametersInput record {
    boolean? negate?;
    string? name?;
    string pattern?;
    string operator?;
};

public type ContributionOrder record {
    string direction?;
};

public type ConvertProjectCardNoteToIssueInput record {
    string? clientMutationId?;
    string repositoryId?;
    string? body?;
    string projectCardId?;
    string? title?;
};

public type ConvertPullRequestToDraftInput record {
    string? clientMutationId?;
    string pullRequestId?;
};

public type CopyProjectV2Input record {
    boolean? includeDraftIssues?;
    string? clientMutationId?;
    string ownerId?;
    string title?;
    string projectId?;
};

public type CreateAttributionInvitationInput record {
    string sourceId?;
    string targetId?;
    string? clientMutationId?;
    string ownerId?;
};

public type CreateBranchProtectionRuleInput record {
    boolean? restrictsReviewDismissals?;
    boolean? restrictsPushes?;
    string[]? bypassPullRequestActorIds?;
    string pattern?;
    string[]? reviewDismissalActorIds?;
    boolean? isAdminEnforced?;
    boolean? blocksCreations?;
    boolean? requireLastPushApproval?;
    RequiredStatusCheckInput[]? requiredStatusChecks?;
    boolean? requiresStatusChecks?;
    boolean? lockAllowsFetchAndMerge?;
    int? requiredApprovingReviewCount?;
    boolean? allowsDeletions?;
    string[]? requiredStatusCheckContexts?;
    boolean? requiresConversationResolution?;
    string? clientMutationId?;
    boolean? lockBranch?;
    boolean? dismissesStaleReviews?;
    boolean? allowsForcePushes?;
    string[]? bypassForcePushActorIds?;
    boolean? requiresApprovingReviews?;
    boolean? requiresCodeOwnerReviews?;
    string repositoryId?;
    boolean? requiresLinearHistory?;
    string[]? requiredDeploymentEnvironments?;
    boolean? requiresDeployments?;
    string[]? pushActorIds?;
    boolean? requiresCommitSignatures?;
    boolean? requiresStrictStatusChecks?;
};

public type CreateCheckRunInput record {
    string? conclusion?;
    CheckRunOutput? output?;
    anydata? completedAt?;
    anydata? detailsUrl?;
    string? clientMutationId?;
    string name?;
    string repositoryId?;
    string? externalId?;
    anydata? startedAt?;
    anydata headSha?;
    CheckRunAction[]? actions?;
    string? status?;
};

public type CreateCheckSuiteInput record {
    string? clientMutationId?;
    string repositoryId?;
    anydata headSha?;
};

public type CreateCommitOnBranchInput record {
    string? clientMutationId?;
    CommitMessage message?;
    CommittableBranch branch?;
    anydata expectedHeadOid?;
    FileChanges? fileChanges?;
};

public type CreateDeploymentInput record {
    string? environment?;
    string[]? requiredContexts?;
    string? task?;
    string? payload?;
    string? clientMutationId?;
    boolean? autoMerge?;
    string repositoryId?;
    string? description?;
    string refId?;
};

public type CreateDeploymentStatusInput record {
    boolean? autoInactive?;
    string? environment?;
    string? clientMutationId?;
    string deploymentId?;
    string? description?;
    string state?;
    string? logUrl?;
    string? environmentUrl?;
};

public type CreateDiscussionInput record {
    string? clientMutationId?;
    string repositoryId?;
    string body?;
    string title?;
    string categoryId?;
};

public type CreateEnterpriseOrganizationInput record {
    string profileName?;
    string billingEmail?;
    string? clientMutationId?;
    string[] adminLogins?;
    string enterpriseId?;
    string login?;
};

public type CreateEnvironmentInput record {
    string? clientMutationId?;
    string name?;
    string repositoryId?;
};

public type CreateIpAllowListEntryInput record {
    string? clientMutationId?;
    string? name?;
    string allowListValue?;
    boolean isActive?;
    string ownerId?;
};

public type CreateIssueInput record {
    string[]? labelIds?;
    string? clientMutationId?;
    string? milestoneId?;
    string repositoryId?;
    string[]? projectIds?;
    string? body?;
    string title?;
    string[]? assigneeIds?;
    string? issueTemplate?;
};

public type CreateLabelInput record {
    string color?;
    string? clientMutationId?;
    string name?;
    string repositoryId?;
    string? description?;
};

public type CreateLinkedBranchInput record {
    string issueId?;
    string? clientMutationId?;
    string? name?;
    string? repositoryId?;
    anydata oid?;
};

public type CreateMigrationSourceInput record {
    string? clientMutationId?;
    string name?;
    string? accessToken?;
    string ownerId?;
    string? githubPat?;
    string 'type?;
    string? url?;
};

public type CreateProjectInput record {
    string? template?;
    string[]? repositoryIds?;
    string? clientMutationId?;
    string name?;
    string? body?;
    string ownerId?;
};

public type CreateProjectV2FieldInput record {
    string? clientMutationId?;
    string dataType?;
    string name?;
    ProjectV2SingleSelectFieldOptionInput[]? singleSelectOptions?;
    string projectId?;
};

public type CreateProjectV2Input record {
    string? clientMutationId?;
    string? teamId?;
    string? repositoryId?;
    string ownerId?;
    string title?;
};

public type CreatePullRequestInput record {
    string baseRefName?;
    string? clientMutationId?;
    string? headRepositoryId?;
    boolean? draft?;
    string repositoryId?;
    boolean? maintainerCanModify?;
    string? body?;
    string title?;
    string headRefName?;
};

public type CreateRefInput record {
    string? clientMutationId?;
    string name?;
    string repositoryId?;
    anydata oid?;
};

public type CreateRepositoryInput record {
    boolean? hasIssuesEnabled?;
    boolean? template?;
    anydata? homepageUrl?;
    string visibility?;
    boolean? hasWikiEnabled?;
    string? clientMutationId?;
    string? teamId?;
    string name?;
    string? description?;
    string? ownerId?;
};

public type CreateRepositoryRulesetInput record {
    string sourceId?;
    string[]? bypassActorIds?;
    string? clientMutationId?;
    string? bypassMode?;
    string enforcement?;
    string name?;
    RepositoryRuleInput[]? rules?;
    RepositoryRuleConditionsInput conditions?;
    string? target?;
};

public type CreateSponsorsListingInput record {
    string? fiscallyHostedProjectProfileUrl?;
    string? billingCountryOrRegionCode?;
    string? sponsorableLogin?;
    string? contactEmail?;
    string? clientMutationId?;
    string? fiscalHostLogin?;
    string? fullDescription?;
    string? residenceCountryOrRegionCode?;
};

public type CreateSponsorsTierInput record {
    int amount?;
    string? sponsorableLogin?;
    string? clientMutationId?;
    boolean? publish?;
    string? welcomeMessage?;
    string? repositoryId?;
    string? repositoryOwnerLogin?;
    string description?;
    boolean? isRecurring?;
    string? repositoryName?;
    string? sponsorableId?;
};

public type CreateSponsorshipInput record {
    int? amount?;
    string? privacyLevel?;
    string? sponsorableLogin?;
    string? tierId?;
    string? clientMutationId?;
    string? sponsorId?;
    boolean? isRecurring?;
    boolean? receiveEmails?;
    string? sponsorLogin?;
    string? sponsorableId?;
};

public type CreateSponsorshipsInput record {
    string? privacyLevel?;
    string? clientMutationId?;
    boolean? receiveEmails?;
    string sponsorLogin?;
    BulkSponsorship[] sponsorships?;
};

public type CreateTeamDiscussionCommentInput record {
    string? clientMutationId?;
    string discussionId?;
    string body?;
};

public type CreateTeamDiscussionInput record {
    boolean? 'private?;
    string? clientMutationId?;
    string teamId?;
    string body?;
    string title?;
};

public type DeclineTopicSuggestionInput record {
    string reason?;
    string? clientMutationId?;
    string name?;
    string repositoryId?;
};

public type DeleteBranchProtectionRuleInput record {
    string? clientMutationId?;
    string branchProtectionRuleId?;
};

public type DeleteDeploymentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteDiscussionCommentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteDiscussionInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteEnvironmentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteIpAllowListEntryInput record {
    string? clientMutationId?;
    string ipAllowListEntryId?;
};

public type DeleteIssueCommentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteIssueInput record {
    string issueId?;
    string? clientMutationId?;
};

public type DeleteLabelInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteLinkedBranchInput record {
    string linkedBranchId?;
    string? clientMutationId?;
};

public type DeletePackageVersionInput record {
    string packageVersionId?;
    string? clientMutationId?;
};

public type DeleteProjectCardInput record {
    string? clientMutationId?;
    string cardId?;
};

public type DeleteProjectColumnInput record {
    string? clientMutationId?;
    string columnId?;
};

public type DeleteProjectInput record {
    string? clientMutationId?;
    string projectId?;
};

public type DeleteProjectV2FieldInput record {
    string? clientMutationId?;
    string fieldId?;
};

public type DeleteProjectV2Input record {
    string? clientMutationId?;
    string projectId?;
};

public type DeleteProjectV2ItemInput record {
    string itemId?;
    string? clientMutationId?;
    string projectId?;
};

public type DeleteProjectV2WorkflowInput record {
    string? clientMutationId?;
    string workflowId?;
};

public type DeletePullRequestReviewCommentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeletePullRequestReviewInput record {
    string pullRequestReviewId?;
    string? clientMutationId?;
};

public type DeleteRefInput record {
    string? clientMutationId?;
    string refId?;
};

public type DeleteRepositoryRulesetInput record {
    string? clientMutationId?;
    string repositoryRulesetId?;
};

public type DeleteTeamDiscussionCommentInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteTeamDiscussionInput record {
    string? clientMutationId?;
    string id?;
};

public type DeleteVerifiableDomainInput record {
    string? clientMutationId?;
    string id?;
};

public type DeploymentOrder record {
    string 'field?;
    string direction?;
};

public type DequeuePullRequestInput record {
    string? clientMutationId?;
    string id?;
};

public type DisablePullRequestAutoMergeInput record {
    string? clientMutationId?;
    string pullRequestId?;
};

public type DiscussionOrder record {
    string 'field?;
    string direction?;
};

public type DiscussionPollOptionOrder record {
    string 'field?;
    string direction?;
};

public type DismissPullRequestReviewInput record {
    string pullRequestReviewId?;
    string? clientMutationId?;
    string message?;
};

public type DismissRepositoryVulnerabilityAlertInput record {
    string dismissReason?;
    string? clientMutationId?;
    string repositoryVulnerabilityAlertId?;
};

public type DraftPullRequestReviewComment record {
    string path?;
    int position?;
    string body?;
};

public type DraftPullRequestReviewThread record {
    string path?;
    string? side?;
    int line?;
    int? startLine?;
    string body?;
    string? startSide?;
};

public type EnablePullRequestAutoMergeInput record {
    string? commitBody?;
    string? authorEmail?;
    string? mergeMethod?;
    string? clientMutationId?;
    string? commitHeadline?;
    string pullRequestId?;
    anydata? expectedHeadOid?;
};

public type EnqueuePullRequestInput record {
    string? clientMutationId?;
    string pullRequestId?;
    anydata? expectedHeadOid?;
    boolean? jump?;
};

public type EnterpriseAdministratorInvitationOrder record {
    string 'field?;
    string direction?;
};

public type EnterpriseMemberOrder record {
    string 'field?;
    string direction?;
};

public type EnterpriseServerInstallationOrder record {
    string 'field?;
    string direction?;
};

public type EnterpriseServerUserAccountEmailOrder record {
    string 'field?;
    string direction?;
};

public type EnterpriseServerUserAccountOrder record {
    string 'field?;
    string direction?;
};

public type EnterpriseServerUserAccountsUploadOrder record {
    string 'field?;
    string direction?;
};

public type FileAddition record {
    string path?;
    anydata contents?;
};

public type FileChanges record {
    FileAddition[]? additions?;
    FileDeletion[]? deletions?;
};

public type FileDeletion record {
    string path?;
};

public type FollowOrganizationInput record {
    string organizationId?;
    string? clientMutationId?;
};

public type FollowUserInput record {
    string? clientMutationId?;
    string userId?;
};

public type GistOrder record {
    string 'field?;
    string direction?;
};

public type GrantEnterpriseOrganizationsMigratorRoleInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type GrantMigratorRoleInput record {
    string actor?;
    string organizationId?;
    string actorType?;
    string? clientMutationId?;
};

public type ImportProjectInput record {
    ProjectColumnImport[] columnImports?;
    boolean? 'public?;
    string ownerName?;
    string? clientMutationId?;
    string name?;
    string? body?;
};

public type InviteEnterpriseAdminInput record {
    string? role?;
    string? clientMutationId?;
    string enterpriseId?;
    string? email?;
    string? invitee?;
};

public type IpAllowListEntryOrder record {
    string 'field?;
    string direction?;
};

public type IssueCommentOrder record {
    string 'field?;
    string direction?;
};

public type IssueFilters record {
    boolean? viewerSubscribed?;
    string? milestone?;
    string? createdBy?;
    string? assignee?;
    string? mentioned?;
    string? milestoneNumber?;
    string[]? labels?;
    anydata? since?;
    string[]? states?;
};

public type IssueOrder record {
    string 'field?;
    string direction?;
};

public type LabelOrder record {
    string 'field?;
    string direction?;
};

public type LanguageOrder record {
    string 'field?;
    string direction?;
};

public type LinkProjectV2ToRepositoryInput record {
    string? clientMutationId?;
    string repositoryId?;
    string projectId?;
};

public type LinkProjectV2ToTeamInput record {
    string? clientMutationId?;
    string teamId?;
    string projectId?;
};

public type LinkRepositoryToProjectInput record {
    string? clientMutationId?;
    string repositoryId?;
    string projectId?;
};

public type LockLockableInput record {
    string lockableId?;
    string? clientMutationId?;
    string? lockReason?;
};

public type MannequinOrder record {
    string 'field?;
    string direction?;
};

public type MarkDiscussionCommentAsAnswerInput record {
    string? clientMutationId?;
    string id?;
};

public type MarkFileAsViewedInput record {
    string path?;
    string? clientMutationId?;
    string pullRequestId?;
};

public type MarkProjectV2AsTemplateInput record {
    string? clientMutationId?;
    string projectId?;
};

public type MarkPullRequestReadyForReviewInput record {
    string? clientMutationId?;
    string pullRequestId?;
};

public type MergeBranchInput record {
    string head?;
    string? authorEmail?;
    string? commitMessage?;
    string? clientMutationId?;
    string repositoryId?;
    string base?;
};

public type MergePullRequestInput record {
    string? commitBody?;
    string? authorEmail?;
    string? mergeMethod?;
    string? clientMutationId?;
    string? commitHeadline?;
    string pullRequestId?;
    anydata? expectedHeadOid?;
};

public type MilestoneOrder record {
    string 'field?;
    string direction?;
};

public type MinimizeCommentInput record {
    string? clientMutationId?;
    string classifier?;
    string subjectId?;
};

public type MoveProjectCardInput record {
    string? clientMutationId?;
    string columnId?;
    string cardId?;
    string? afterCardId?;
};

public type MoveProjectColumnInput record {
    string? clientMutationId?;
    string columnId?;
    string? afterColumnId?;
};

public type OrgEnterpriseOwnerOrder record {
    string 'field?;
    string direction?;
};

public type OrganizationOrder record {
    string 'field?;
    string direction?;
};

public type PackageFileOrder record {
    string? 'field?;
    string? direction?;
};

public type PackageOrder record {
    string? 'field?;
    string? direction?;
};

public type PackageVersionOrder record {
    string? 'field?;
    string? direction?;
};

public type PinIssueInput record {
    string issueId?;
    string? clientMutationId?;
};

public type ProjectCardImport record {
    int number?;
    string repository?;
};

public type ProjectColumnImport record {
    int position?;
    ProjectCardImport[]? issues?;
    string columnName?;
};

public type ProjectOrder record {
    string 'field?;
    string direction?;
};

public type ProjectV2Collaborator record {
    string role?;
    string? teamId?;
    string? userId?;
};

public type ProjectV2FieldOrder record {
    string 'field?;
    string direction?;
};

public type ProjectV2FieldValue record {
    anydata? date?;
    float? number?;
    string? text?;
    string? iterationId?;
    string? singleSelectOptionId?;
};

public type ProjectV2Filters record {
    string? state?;
};

public type ProjectV2ItemFieldValueOrder record {
    string 'field?;
    string direction?;
};

public type ProjectV2ItemOrder record {
    string 'field?;
    string direction?;
};

public type ProjectV2Order record {
    string 'field?;
    string direction?;
};

public type ProjectV2SingleSelectFieldOptionInput record {
    string color?;
    string name?;
    string description?;
};

public type ProjectV2ViewOrder record {
    string 'field?;
    string direction?;
};

public type ProjectV2WorkflowOrder record {
    string 'field?;
    string direction?;
};

public type PublishSponsorsTierInput record {
    string tierId?;
    string? clientMutationId?;
};

public type PullRequestOrder record {
    string 'field?;
    string direction?;
};

public type PullRequestParametersInput record {
    boolean requiredReviewThreadResolution?;
    boolean dismissStaleReviewsOnPush?;
    int requiredApprovingReviewCount?;
    boolean requireCodeOwnerReview?;
    boolean requireLastPushApproval?;
};

public type ReactionOrder record {
    string 'field?;
    string direction?;
};

public type RefNameConditionTargetInput record {
    string[] include?;
    string[] exclude?;
};

public type RefOrder record {
    string 'field?;
    string direction?;
};

public type RefUpdate record {
    anydata name?;
    anydata afterOid?;
    boolean? force?;
    anydata? beforeOid?;
};

public type RegenerateEnterpriseIdentityProviderRecoveryCodesInput record {
    string? clientMutationId?;
    string enterpriseId?;
};

public type RegenerateVerifiableDomainTokenInput record {
    string? clientMutationId?;
    string id?;
};

public type RejectDeploymentsInput record {
    string? clientMutationId?;
    string[] environmentIds?;
    string? comment?;
    string workflowRunId?;
};

public type ReleaseOrder record {
    string 'field?;
    string direction?;
};

public type RemoveAssigneesFromAssignableInput record {
    string? clientMutationId?;
    string assignableId?;
    string[] assigneeIds?;
};

public type RemoveEnterpriseAdminInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type RemoveEnterpriseIdentityProviderInput record {
    string? clientMutationId?;
    string enterpriseId?;
};

public type RemoveEnterpriseMemberInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string userId?;
};

public type RemoveEnterpriseOrganizationInput record {
    string organizationId?;
    string? clientMutationId?;
    string enterpriseId?;
};

public type RemoveEnterpriseSupportEntitlementInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type RemoveLabelsFromLabelableInput record {
    string[] labelIds?;
    string? clientMutationId?;
    string labelableId?;
};

public type RemoveOutsideCollaboratorInput record {
    string organizationId?;
    string? clientMutationId?;
    string userId?;
};

public type RemoveReactionInput record {
    string? clientMutationId?;
    string content?;
    string subjectId?;
};

public type RemoveStarInput record {
    string? clientMutationId?;
    string starrableId?;
};

public type RemoveUpvoteInput record {
    string? clientMutationId?;
    string subjectId?;
};

public type ReopenDiscussionInput record {
    string? clientMutationId?;
    string discussionId?;
};

public type ReopenIssueInput record {
    string issueId?;
    string? clientMutationId?;
};

public type ReopenPullRequestInput record {
    string? clientMutationId?;
    string pullRequestId?;
};

public type RepositoryInvitationOrder record {
    string 'field?;
    string direction?;
};

public type RepositoryMigrationOrder record {
    string 'field?;
    string direction?;
};

public type RepositoryNameConditionTargetInput record {
    string[] include?;
    boolean? protected?;
    string[] exclude?;
};

public type RepositoryOrder record {
    string 'field?;
    string direction?;
};

public type RepositoryRuleConditionsInput record {
    RefNameConditionTargetInput? refName?;
    RepositoryNameConditionTargetInput? repositoryName?;
};

public type RepositoryRuleInput record {
    string? id?;
    RuleParametersInput? parameters?;
    string 'type?;
};

public type RequestReviewsInput record {
    string? clientMutationId?;
    string[]? userIds?;
    boolean? union?;
    string pullRequestId?;
    string[]? teamIds?;
};

public type RequiredDeploymentsParametersInput record {
    string[] requiredDeploymentEnvironments?;
};

public type RequiredStatusCheckInput record {
    string? appId?;
    string context?;
};

public type RequiredStatusChecksParametersInput record {
    StatusCheckConfigurationInput[] requiredStatusChecks?;
    boolean strictRequiredStatusChecksPolicy?;
};

public type RerequestCheckSuiteInput record {
    string? clientMutationId?;
    string checkSuiteId?;
    string repositoryId?;
};

public type ResolveReviewThreadInput record {
    string threadId?;
    string? clientMutationId?;
};

public type RetireSponsorsTierInput record {
    string tierId?;
    string? clientMutationId?;
};

public type RevertPullRequestInput record {
    string? clientMutationId?;
    boolean? draft?;
    string? body?;
    string pullRequestId?;
    string? title?;
};

public type RevokeEnterpriseOrganizationsMigratorRoleInput record {
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type RevokeMigratorRoleInput record {
    string actor?;
    string organizationId?;
    string actorType?;
    string? clientMutationId?;
};

public type RuleParametersInput record {
    RequiredStatusChecksParametersInput? requiredStatusChecks?;
    BranchNamePatternParametersInput? branchNamePattern?;
    CommitAuthorEmailPatternParametersInput? commitAuthorEmailPattern?;
    CommitterEmailPatternParametersInput? committerEmailPattern?;
    TagNamePatternParametersInput? tagNamePattern?;
    UpdateParametersInput? update?;
    CommitMessagePatternParametersInput? commitMessagePattern?;
    PullRequestParametersInput? pullRequest?;
    RequiredDeploymentsParametersInput? requiredDeployments?;
};

public type SavedReplyOrder record {
    string 'field?;
    string direction?;
};

public type SecurityAdvisoryIdentifierFilter record {
    string 'type?;
    string value?;
};

public type SecurityAdvisoryOrder record {
    string 'field?;
    string direction?;
};

public type SecurityVulnerabilityOrder record {
    string 'field?;
    string direction?;
};

public type SetEnterpriseIdentityProviderInput record {
    string idpCertificate?;
    anydata ssoUrl?;
    string? clientMutationId?;
    string digestMethod?;
    string signatureMethod?;
    string enterpriseId?;
    string? issuer?;
};

public type SetOrganizationInteractionLimitInput record {
    string organizationId?;
    string 'limit?;
    string? clientMutationId?;
    string? expiry?;
};

public type SetRepositoryInteractionLimitInput record {
    string 'limit?;
    string? clientMutationId?;
    string repositoryId?;
    string? expiry?;
};

public type SetUserInteractionLimitInput record {
    string 'limit?;
    string? clientMutationId?;
    string? expiry?;
    string userId?;
};

public type SponsorOrder record {
    string 'field?;
    string direction?;
};

public type SponsorableOrder record {
    string 'field?;
    string direction?;
};

public type SponsorsActivityOrder record {
    string 'field?;
    string direction?;
};

public type SponsorsTierOrder record {
    string 'field?;
    string direction?;
};

public type SponsorshipNewsletterOrder record {
    string 'field?;
    string direction?;
};

public type SponsorshipOrder record {
    string 'field?;
    string direction?;
};

public type StarOrder record {
    string 'field?;
    string direction?;
};

public type StartOrganizationMigrationInput record {
    string targetOrgName?;
    string sourceAccessToken?;
    string? clientMutationId?;
    anydata sourceOrgUrl?;
    string targetEnterpriseId?;
};

public type StartRepositoryMigrationInput record {
    string sourceId?;
    string? clientMutationId?;
    string? targetRepoVisibility?;
    boolean? lockSource?;
    string? accessToken?;
    string ownerId?;
    string repositoryName?;
    anydata? sourceRepositoryUrl?;
    string? githubPat?;
    boolean? continueOnError?;
    string? gitArchiveUrl?;
    boolean? skipReleases?;
    string? metadataArchiveUrl?;
};

public type StatusCheckConfigurationInput record {
    string context?;
    int? integrationId?;
};

public type SubmitPullRequestReviewInput record {
    string? pullRequestReviewId?;
    string? clientMutationId?;
    string? body?;
    string event?;
    string? pullRequestId?;
};

public type TagNamePatternParametersInput record {
    boolean? negate?;
    string? name?;
    string pattern?;
    string operator?;
};

public type TeamDiscussionCommentOrder record {
    string 'field?;
    string direction?;
};

public type TeamDiscussionOrder record {
    string 'field?;
    string direction?;
};

public type TeamMemberOrder record {
    string 'field?;
    string direction?;
};

public type TeamOrder record {
    string 'field?;
    string direction?;
};

public type TeamRepositoryOrder record {
    string 'field?;
    string direction?;
};

public type TransferEnterpriseOrganizationInput record {
    string organizationId?;
    string? clientMutationId?;
    string destinationEnterpriseId?;
};

public type TransferIssueInput record {
    string issueId?;
    string? clientMutationId?;
    string repositoryId?;
    boolean? createLabelsIfMissing?;
};

public type UnarchiveProjectV2ItemInput record {
    string itemId?;
    string? clientMutationId?;
    string projectId?;
};

public type UnarchiveRepositoryInput record {
    string? clientMutationId?;
    string repositoryId?;
};

public type UnfollowOrganizationInput record {
    string organizationId?;
    string? clientMutationId?;
};

public type UnfollowUserInput record {
    string? clientMutationId?;
    string userId?;
};

public type UnlinkProjectV2FromRepositoryInput record {
    string? clientMutationId?;
    string repositoryId?;
    string projectId?;
};

public type UnlinkProjectV2FromTeamInput record {
    string? clientMutationId?;
    string teamId?;
    string projectId?;
};

public type UnlinkRepositoryFromProjectInput record {
    string? clientMutationId?;
    string repositoryId?;
    string projectId?;
};

public type UnlockLockableInput record {
    string lockableId?;
    string? clientMutationId?;
};

public type UnmarkDiscussionCommentAsAnswerInput record {
    string? clientMutationId?;
    string id?;
};

public type UnmarkFileAsViewedInput record {
    string path?;
    string? clientMutationId?;
    string pullRequestId?;
};

public type UnmarkIssueAsDuplicateInput record {
    string canonicalId?;
    string? clientMutationId?;
    string duplicateId?;
};

public type UnmarkProjectV2AsTemplateInput record {
    string? clientMutationId?;
    string projectId?;
};

public type UnminimizeCommentInput record {
    string? clientMutationId?;
    string subjectId?;
};

public type UnpinIssueInput record {
    string issueId?;
    string? clientMutationId?;
};

public type UnresolveReviewThreadInput record {
    string threadId?;
    string? clientMutationId?;
};

public type UpdateBranchProtectionRuleInput record {
    boolean? restrictsReviewDismissals?;
    boolean? restrictsPushes?;
    string[]? bypassPullRequestActorIds?;
    string? pattern?;
    string[]? reviewDismissalActorIds?;
    boolean? isAdminEnforced?;
    boolean? blocksCreations?;
    boolean? requireLastPushApproval?;
    RequiredStatusCheckInput[]? requiredStatusChecks?;
    boolean? requiresStatusChecks?;
    boolean? lockAllowsFetchAndMerge?;
    int? requiredApprovingReviewCount?;
    boolean? allowsDeletions?;
    string[]? requiredStatusCheckContexts?;
    boolean? requiresConversationResolution?;
    string? clientMutationId?;
    boolean? lockBranch?;
    boolean? dismissesStaleReviews?;
    string branchProtectionRuleId?;
    boolean? allowsForcePushes?;
    string[]? bypassForcePushActorIds?;
    boolean? requiresApprovingReviews?;
    boolean? requiresCodeOwnerReviews?;
    boolean? requiresLinearHistory?;
    string[]? requiredDeploymentEnvironments?;
    boolean? requiresDeployments?;
    string[]? pushActorIds?;
    boolean? requiresCommitSignatures?;
    boolean? requiresStrictStatusChecks?;
};

public type UpdateCheckRunInput record {
    string? conclusion?;
    CheckRunOutput? output?;
    anydata? completedAt?;
    anydata? detailsUrl?;
    string? clientMutationId?;
    string? name?;
    string repositoryId?;
    string? externalId?;
    anydata? startedAt?;
    string checkRunId?;
    CheckRunAction[]? actions?;
    string? status?;
};

public type UpdateCheckSuitePreferencesInput record {
    string? clientMutationId?;
    string repositoryId?;
    CheckSuiteAutoTriggerPreference[] autoTriggerPreferences?;
};

public type UpdateDiscussionCommentInput record {
    string? clientMutationId?;
    string commentId?;
    string body?;
};

public type UpdateDiscussionInput record {
    string? clientMutationId?;
    string discussionId?;
    string? body?;
    string? title?;
    string? categoryId?;
};

public type UpdateEnterpriseAdministratorRoleInput record {
    string role?;
    string? clientMutationId?;
    string enterpriseId?;
    string login?;
};

public type UpdateEnterpriseAllowPrivateRepositoryForkingSettingInput record {
    string? policyValue?;
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseDefaultRepositoryPermissionSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanChangeRepositoryVisibilitySettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanCreateRepositoriesSettingInput record {
    boolean? membersCanCreatePrivateRepositories?;
    boolean? membersCanCreatePublicRepositories?;
    boolean? membersCanCreateInternalRepositories?;
    string? clientMutationId?;
    boolean? membersCanCreateRepositoriesPolicyEnabled?;
    string? settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanDeleteIssuesSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanDeleteRepositoriesSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanInviteCollaboratorsSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanMakePurchasesSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanUpdateProtectedBranchesSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseMembersCanViewDependencyInsightsSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseOrganizationProjectsSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseOwnerOrganizationRoleInput record {
    string organizationId?;
    string organizationRole?;
    string? clientMutationId?;
    string enterpriseId?;
};

public type UpdateEnterpriseProfileInput record {
    string? websiteUrl?;
    string? clientMutationId?;
    string? name?;
    string? description?;
    string? location?;
    string enterpriseId?;
};

public type UpdateEnterpriseRepositoryProjectsSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseTeamDiscussionsSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnterpriseTwoFactorAuthenticationRequiredSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string enterpriseId?;
};

public type UpdateEnvironmentInput record {
    string environmentId?;
    int? waitTimer?;
    string? clientMutationId?;
    string[]? reviewers?;
};

public type UpdateIpAllowListEnabledSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string ownerId?;
};

public type UpdateIpAllowListEntryInput record {
    string? clientMutationId?;
    string ipAllowListEntryId?;
    string? name?;
    string allowListValue?;
    boolean isActive?;
};

public type UpdateIpAllowListForInstalledAppsEnabledSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string ownerId?;
};

public type UpdateIssueCommentInput record {
    string? clientMutationId?;
    string id?;
    string body?;
};

public type UpdateIssueInput record {
    string[]? labelIds?;
    string? clientMutationId?;
    string? milestoneId?;
    string id?;
    string[]? projectIds?;
    string? state?;
    string? body?;
    string? title?;
    string[]? assigneeIds?;
};

public type UpdateLabelInput record {
    string? color?;
    string? clientMutationId?;
    string? name?;
    string? description?;
    string id?;
};

public type UpdateNotificationRestrictionSettingInput record {
    string? clientMutationId?;
    string settingValue?;
    string ownerId?;
};

public type UpdateOrganizationAllowPrivateRepositoryForkingSettingInput record {
    string organizationId?;
    string? clientMutationId?;
    boolean forkingEnabled?;
};

public type UpdateOrganizationWebCommitSignoffSettingInput record {
    string organizationId?;
    boolean webCommitSignoffRequired?;
    string? clientMutationId?;
};

public type UpdateParametersInput record {
    boolean updateAllowsFetchAndMerge?;
};

public type UpdateProjectCardInput record {
    string? note?;
    string? clientMutationId?;
    boolean? isArchived?;
    string projectCardId?;
};

public type UpdateProjectColumnInput record {
    string? clientMutationId?;
    string name?;
    string projectColumnId?;
};

public type UpdateProjectInput record {
    boolean? 'public?;
    string? clientMutationId?;
    string? name?;
    string? state?;
    string? body?;
    string projectId?;
};

public type UpdateProjectV2CollaboratorsInput record {
    string? clientMutationId?;
    ProjectV2Collaborator[] collaborators?;
    string projectId?;
};

public type UpdateProjectV2DraftIssueInput record {
    string? clientMutationId?;
    string? body?;
    string? title?;
    string[]? assigneeIds?;
    string draftIssueId?;
};

public type UpdateProjectV2Input record {
    boolean? 'public?;
    string? clientMutationId?;
    boolean? closed?;
    string? readme?;
    string? shortDescription?;
    string? title?;
    string projectId?;
};

public type UpdateProjectV2ItemFieldValueInput record {
    string itemId?;
    string? clientMutationId?;
    string projectId?;
    ProjectV2FieldValue value?;
    string fieldId?;
};

public type UpdateProjectV2ItemPositionInput record {
    string itemId?;
    string? clientMutationId?;
    string? afterId?;
    string projectId?;
};

public type UpdatePullRequestBranchInput record {
    string? clientMutationId?;
    string pullRequestId?;
    anydata? expectedHeadOid?;
};

public type UpdatePullRequestInput record {
    string? baseRefName?;
    string[]? labelIds?;
    string? clientMutationId?;
    string? milestoneId?;
    boolean? maintainerCanModify?;
    string[]? projectIds?;
    string? state?;
    string? body?;
    string pullRequestId?;
    string? title?;
    string[]? assigneeIds?;
};

public type UpdatePullRequestReviewCommentInput record {
    string pullRequestReviewCommentId?;
    string? clientMutationId?;
    string body?;
};

public type UpdatePullRequestReviewInput record {
    string pullRequestReviewId?;
    string? clientMutationId?;
    string body?;
};

public type UpdateRefInput record {
    string? clientMutationId?;
    boolean? force?;
    anydata oid?;
    string refId?;
};

public type UpdateRefsInput record {
    string? clientMutationId?;
    string repositoryId?;
    RefUpdate[] refUpdates?;
};

public type UpdateRepositoryInput record {
    boolean? hasIssuesEnabled?;
    boolean? hasProjectsEnabled?;
    boolean? template?;
    anydata? homepageUrl?;
    boolean? hasWikiEnabled?;
    string? clientMutationId?;
    string? name?;
    string repositoryId?;
    string? description?;
    boolean? hasDiscussionsEnabled?;
};

public type UpdateRepositoryRulesetInput record {
    string[]? bypassActorIds?;
    string? clientMutationId?;
    string? bypassMode?;
    string? enforcement?;
    string? name?;
    string repositoryRulesetId?;
    RepositoryRuleInput[]? rules?;
    RepositoryRuleConditionsInput? conditions?;
    string? target?;
};

public type UpdateRepositoryWebCommitSignoffSettingInput record {
    boolean webCommitSignoffRequired?;
    string? clientMutationId?;
    string repositoryId?;
};

public type UpdateSponsorshipPreferencesInput record {
    string? privacyLevel?;
    string? sponsorableLogin?;
    string? clientMutationId?;
    string? sponsorId?;
    boolean? receiveEmails?;
    string? sponsorLogin?;
    string? sponsorableId?;
};

public type UpdateSubscriptionInput record {
    string? clientMutationId?;
    string state?;
    string subscribableId?;
};

public type UpdateTeamDiscussionCommentInput record {
    string? clientMutationId?;
    string id?;
    string body?;
    string? bodyVersion?;
};

public type UpdateTeamDiscussionInput record {
    boolean? pinned?;
    string? clientMutationId?;
    string id?;
    string? body?;
    string? title?;
    string? bodyVersion?;
};

public type UpdateTeamReviewAssignmentInput record {
    string? clientMutationId?;
    boolean? notifyTeam?;
    int? teamMemberCount?;
    string id?;
    boolean enabled?;
    string[]? excludedTeamMemberIds?;
    string? algorithm?;
};

public type UpdateTeamsRepositoryInput record {
    string? clientMutationId?;
    string repositoryId?;
    string permission?;
    string[] teamIds?;
};

public type UpdateTopicsInput record {
    string[] topicNames?;
    string? clientMutationId?;
    string repositoryId?;
};

public type UserStatusOrder record {
    string 'field?;
    string direction?;
};

public type VerifiableDomainOrder record {
    string 'field?;
    string direction?;
};

public type VerifyVerifiableDomainInput record {
    string? clientMutationId?;
    string id?;
};

public type WorkflowRunOrder record {
    string 'field?;
    string direction?;
};

public type GetBranchesResponse record {|
    map<json?> __extensions?;
    record {|
        record {|
            record {|
                string name;
                string id;
                string prefix;
            |}?[]? nodes;
        |}? refs;
    |}? repository;
|};
