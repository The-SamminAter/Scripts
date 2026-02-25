#/bin/bash
school=""
if [[ -z ${school} ]] && [[ "$3" != "-s" ]]
then
	echo "Please edit this script to set your school as \$school, or use -s \"{school}\" (incompatible with -c)"
	exit 1
elif [[ "$3" == "-s" && ! -z $4 ]]
then
	school="$4" #I hope ya remembered to put the school in quotes now
fi

if [[ $1 == "-h" || $1 == "--help" ]]
then
	echo "RateMyProfessor CLI"
	echo "Use:"
	echo "{firstname} {lastname}		Searches RMP, returns profile if found with latest 3 comments"
	echo "{fn} {ln} -c {num}		Returns profile with \$num latest comments"
	echo "{fn} {ln} -s \"school\"		Returns profile from \$school"
	exit 0
fi
name="$1 $2"
ID=$(curl --silent 'https://www.ratemyprofessors.com/graphql' -H 'Content-Type: application/json' --data-raw '{"query":"query NewSearchTeachersQuery(\n  $query: TeacherSearchQuery!\n  $count: Int\n  $includeCompare: Boolean!\n) {\n  newSearch {\n    teachers(query: $query, first: $count) {\n      didFallback\n      edges {\n        cursor\n        node {\n          id\n          legacyId\n          firstName\n          lastName\n          department\n          departmentId\n          school {\n            legacyId\n            name\n            id\n          }\n          ...CompareProfessorsColumn_teacher @include(if: $includeCompare)\n        }\n      }\n    }\n  }\n}\n\nfragment CompareProfessorsColumn_teacher on Teacher {\n  id\n  legacyId\n  firstName\n  lastName\n  school {\n    legacyId\n    name\n    id\n  }\n  department\n  departmentId\n  avgRating\n  avgDifficulty\n  numRatings\n  wouldTakeAgainPercentRounded\n  mandatoryAttendance {\n    yes\n    no\n    neither\n    total\n  }\n  takenForCredit {\n    yes\n    no\n    neither\n    total\n  }\n  ...NoRatingsArea_teacher\n  ...RatingDistributionWrapper_teacher\n}\n\nfragment NoRatingsArea_teacher on Teacher {\n  lastName\n  ...RateTeacherLink_teacher\n}\n\nfragment RateTeacherLink_teacher on Teacher {\n  legacyId\n  numRatings\n  lockStatus\n}\n\nfragment RatingDistributionChart_ratingsDistribution on ratingsDistribution {\n  r1\n  r2\n  r3\n  r4\n  r5\n}\n\nfragment RatingDistributionWrapper_teacher on Teacher {\n  ...NoRatingsArea_teacher\n  ratingsDistribution {\n    total\n    ...RatingDistributionChart_ratingsDistribution\n  }\n}\n","operationName":"NewSearchTeachersQuery","variables":{"query":{"text":"'"${name}"'"},"count":10,"includeCompare":false}}' | jq '.data.newSearch.teachers.edges.[] | select(.node.school.name == "'"${school}"'") | .node.id' | tr -d '"')
if [[ -z ${ID} ]]
then
	echo "Professor not found"
	exit 1
fi
data=$(curl --silent 'https://www.ratemyprofessors.com/graphql' -H 'Content-Type: application/json' --data-raw '{"query":"query TeacherRatingsPageQuery(\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ... on Teacher {\n      id\n      legacyId\n      firstName\n      lastName\n      department\n      school {\n        legacyId\n        name\n        city\n        state\n        country\n        id\n      }\n      lockStatus\n      ...StickyHeaderContent_teacher\n      ...MiniStickyHeader_teacher\n      ...TeacherBookmark_teacher\n      ...RatingDistributionWrapper_teacher\n      ...TeacherInfo_teacher\n      ...SimilarProfessors_teacher\n      ...TeacherRatingTabs_teacher\n    }\n    id\n  }\n}\n\nfragment CompareProfessorLink_teacher on Teacher {\n  legacyId\n}\n\nfragment CourseMeta_rating on Rating {\n  attendanceMandatory\n  wouldTakeAgain\n  grade\n  textbookUse\n  isForOnlineClass\n  isForCredit\n}\n\nfragment HeaderDescription_teacher on Teacher {\n  id\n  legacyId\n  firstName\n  lastName\n  department\n  school {\n    legacyId\n    name\n    city\n    state\n    id\n  }\n  ...TeacherTitles_teacher\n  ...TeacherBookmark_teacher\n  ...RateTeacherLink_teacher\n  ...CompareProfessorLink_teacher\n}\n\nfragment HeaderRateButton_teacher on Teacher {\n  ...RateTeacherLink_teacher\n  ...CompareProfessorLink_teacher\n}\n\nfragment MiniStickyHeader_teacher on Teacher {\n  id\n  legacyId\n  firstName\n  lastName\n  department\n  departmentId\n  school {\n    legacyId\n    name\n    city\n    state\n    id\n  }\n  ...TeacherBookmark_teacher\n  ...RateTeacherLink_teacher\n  ...CompareProfessorLink_teacher\n}\n\nfragment NameLink_teacher on Teacher {\n  isProfCurrentUser\n  id\n  legacyId\n  firstName\n  lastName\n  school {\n    name\n    id\n  }\n}\n\nfragment NameTitle_teacher on Teacher {\n  id\n  firstName\n  lastName\n  department\n  school {\n    legacyId\n    name\n    id\n  }\n  ...TeacherDepartment_teacher\n  ...TeacherBookmark_teacher\n}\n\nfragment NoRatingsArea_teacher on Teacher {\n  lastName\n  ...RateTeacherLink_teacher\n}\n\nfragment NumRatingsLink_teacher on Teacher {\n  numRatings\n  ...RateTeacherLink_teacher\n}\n\nfragment ProfessorNoteEditor_rating on Rating {\n  id\n  legacyId\n  class\n  teacherNote {\n    id\n    teacherId\n    comment\n  }\n}\n\nfragment ProfessorNoteEditor_teacher on Teacher {\n  id\n}\n\nfragment ProfessorNoteFooter_note on TeacherNotes {\n  legacyId\n  flagStatus\n}\n\nfragment ProfessorNoteFooter_teacher on Teacher {\n  legacyId\n  isProfCurrentUser\n}\n\nfragment ProfessorNoteHeader_note on TeacherNotes {\n  createdAt\n  updatedAt\n}\n\nfragment ProfessorNoteHeader_teacher on Teacher {\n  lastName\n}\n\nfragment ProfessorNoteSection_rating on Rating {\n  teacherNote {\n    ...ProfessorNote_note\n    id\n  }\n  ...ProfessorNoteEditor_rating\n}\n\nfragment ProfessorNoteSection_teacher on Teacher {\n  ...ProfessorNote_teacher\n  ...ProfessorNoteEditor_teacher\n}\n\nfragment ProfessorNote_note on TeacherNotes {\n  comment\n  ...ProfessorNoteHeader_note\n  ...ProfessorNoteFooter_note\n}\n\nfragment ProfessorNote_teacher on Teacher {\n  ...ProfessorNoteHeader_teacher\n  ...ProfessorNoteFooter_teacher\n}\n\nfragment RateTeacherLink_teacher on Teacher {\n  legacyId\n  numRatings\n  lockStatus\n}\n\nfragment RatingDistributionChart_ratingsDistribution on ratingsDistribution {\n  r1\n  r2\n  r3\n  r4\n  r5\n}\n\nfragment RatingDistributionWrapper_teacher on Teacher {\n  ...NoRatingsArea_teacher\n  ratingsDistribution {\n    total\n    ...RatingDistributionChart_ratingsDistribution\n  }\n}\n\nfragment RatingFooter_rating on Rating {\n  id\n  comment\n  adminReviewedAt\n  flagStatus\n  legacyId\n  thumbsUpTotal\n  thumbsDownTotal\n  thumbs {\n    thumbsUp\n    thumbsDown\n    computerId\n    id\n  }\n  teacherNote {\n    id\n  }\n  ...Thumbs_rating\n}\n\nfragment RatingFooter_teacher on Teacher {\n  id\n  legacyId\n  lockStatus\n  isProfCurrentUser\n  ...Thumbs_teacher\n}\n\nfragment RatingHeader_rating on Rating {\n  legacyId\n  date\n  class\n  helpfulRating\n  clarityRating\n  isForOnlineClass\n}\n\nfragment RatingSuperHeader_rating on Rating {\n  legacyId\n}\n\nfragment RatingSuperHeader_teacher on Teacher {\n  firstName\n  lastName\n  legacyId\n  school {\n    name\n    id\n  }\n}\n\nfragment RatingTags_rating on Rating {\n  ratingTags\n}\n\nfragment RatingValue_teacher on Teacher {\n  avgRating\n  numRatings\n  ...NumRatingsLink_teacher\n}\n\nfragment RatingValues_rating on Rating {\n  helpfulRating\n  clarityRating\n  difficultyRating\n}\n\nfragment Rating_rating on Rating {\n  comment\n  flagStatus\n  createdByUser\n  teacherNote {\n    id\n  }\n  ...RatingHeader_rating\n  ...RatingSuperHeader_rating\n  ...RatingValues_rating\n  ...CourseMeta_rating\n  ...RatingTags_rating\n  ...RatingFooter_rating\n  ...ProfessorNoteSection_rating\n}\n\nfragment Rating_teacher on Teacher {\n  ...RatingFooter_teacher\n  ...RatingSuperHeader_teacher\n  ...ProfessorNoteSection_teacher\n}\n\nfragment RatingsFilter_teacher on Teacher {\n  courseCodes {\n    courseCount\n    courseName\n  }\n}\n\nfragment RatingsList_teacher on Teacher {\n  id\n  legacyId\n  lastName\n  numRatings\n  school {\n    id\n    legacyId\n    name\n    city\n    state\n    avgRating\n    numRatings\n  }\n  ...Rating_teacher\n  ...NoRatingsArea_teacher\n  ratings(first: 5) {\n    edges {\n      cursor\n      node {\n        ...Rating_rating\n        id\n        __typename\n      }\n    }\n    pageInfo {\n      hasNextPage\n      endCursor\n    }\n  }\n}\n\nfragment SimilarProfessorListItem_teacher on RelatedTeacher {\n  legacyId\n  firstName\n  lastName\n  avgRating\n}\n\nfragment SimilarProfessors_teacher on Teacher {\n  department\n  relatedTeachers {\n    legacyId\n    ...SimilarProfessorListItem_teacher\n    id\n  }\n}\n\nfragment StickyHeaderContent_teacher on Teacher {\n  ...HeaderDescription_teacher\n  ...HeaderRateButton_teacher\n  ...MiniStickyHeader_teacher\n}\n\nfragment TeacherBookmark_teacher on Teacher {\n  id\n  isSaved\n}\n\nfragment TeacherDepartment_teacher on Teacher {\n  department\n  departmentId\n  school {\n    legacyId\n    name\n    isVisible\n    id\n  }\n}\n\nfragment TeacherFeedback_teacher on Teacher {\n  numRatings\n  avgDifficulty\n  wouldTakeAgainPercent\n}\n\nfragment TeacherInfo_teacher on Teacher {\n  id\n  lastName\n  numRatings\n  ...RatingValue_teacher\n  ...NameTitle_teacher\n  ...TeacherTags_teacher\n  ...NameLink_teacher\n  ...TeacherFeedback_teacher\n  ...RateTeacherLink_teacher\n  ...CompareProfessorLink_teacher\n}\n\nfragment TeacherRatingTabs_teacher on Teacher {\n  numRatings\n  courseCodes {\n    courseName\n    courseCount\n  }\n  ...RatingsList_teacher\n  ...RatingsFilter_teacher\n}\n\nfragment TeacherTags_teacher on Teacher {\n  lastName\n  teacherRatingTags {\n    legacyId\n    tagCount\n    tagName\n    id\n  }\n}\n\nfragment TeacherTitles_teacher on Teacher {\n  department\n  school {\n    legacyId\n    name\n    id\n  }\n}\n\nfragment Thumbs_rating on Rating {\n  id\n  comment\n  adminReviewedAt\n  flagStatus\n  legacyId\n  thumbsUpTotal\n  thumbsDownTotal\n  thumbs {\n    computerId\n    thumbsUp\n    thumbsDown\n    id\n  }\n  teacherNote {\n    id\n  }\n}\n\nfragment Thumbs_teacher on Teacher {\n  id\n  legacyId\n  lockStatus\n  isProfCurrentUser\n}\n","operationName":"TeacherRatingsPageQuery","variables":{"id":"'"${ID}"'"}}' | jq '.data.node')
echo "Name: $(jq '(.firstName, .lastName)' <<< ${data} | tr '\n' ' ' | tr -d '"')"
echo "Department: $(jq '.department' <<< ${data} | tr -d '"')"
echo "Ratings:            $(jq '.numRatings' <<< ${data})"
echo "Average rating:     $(jq '.avgRating' <<< ${data})/5"
echo "Average difficulty: $(jq '.avgDifficulty' <<< ${data})/5"
echo "Would take again:   $(printf %.2f `jq '.wouldTakeAgainPercent' <<< ${data}`)%"
echo ""
echo "Ratings breakdown" #TODO: add bars like on the site

printPercent()
{
width=20
#Listen, I prefer to only do command-in-command two layers deep. However, this seems to be reliable, and while I'm sure I could refactor it, it is good enough
percent=$(printf %.0f $(bc -l <<< "${width} / `jq '.numRatings' <<< ${data}` * $1"))
printf " ["
if [[ "${percent}" != 0 ]]
then
	printf '\e[44m%-.s \e[0m' $(seq 1 ${percent})
fi
if [[ "${percent}" != "${width}" ]]
then
	printf '%-.s ' $(seq 1 $((${width} - ${percent})))
fi
printf "] $1\n"
}

printf "Awesome 5:" && printPercent $(jq '.ratingsDistribution.r5' <<< ${data})
printf "  Great 4:" && printPercent $(jq '.ratingsDistribution.r4' <<< ${data})
printf "   Good 3:" && printPercent $(jq '.ratingsDistribution.r3' <<< ${data})
printf "     OK 2:" && printPercent $(jq '.ratingsDistribution.r2' <<< ${data})
printf "  Awful 1:" && printPercent $(jq '.ratingsDistribution.r1' <<< ${data})

tick=0
if [[ $3 == "-c" && ! -z $4 ]]
then
	max=$4
else
	max=3
fi
if [[ ${max} -gt 0 ]]
then
	echo ""
	echo "Most recent reviews:"
fi
while [[ "${tick}" -lt "${max}" ]]
do
	focus=$(jq '.ratings.edges.['${tick}'].node' <<< ${data})
	echo ""
	echo "Quality: $(jq '.clarityRating' <<< ${focus}) | Difficulty: $(jq '.difficultyRating' <<< ${focus}) | Class: $(jq '.class' <<< ${focus} | tr -d '"') | Date: $(jq '.date' <<< ${focus} | tr -d '"' | awk -F' ' '{print $1}')"
	#I'd prefer not to split words, but this seems to be the 'best' solution a quick google found
	jq '.comment' <<< ${focus} | sed 's/"/""""/g' | column --separator '"' --table --output-width $(bc -l <<< `tput cols`+8) --table-noheadings --table-columns C1,C2,C3,C4,C5 --table-wrap C5 | sed -e 's/\s*$//g'
	echo "	Tags:   $(jq '.ratingTags' <<< ${focus} | tr -d '"' | sed 's/-/--/g' | tr '-' ' ')"
	unset focus
	let tick++
done
#echo "${data}" | jq
