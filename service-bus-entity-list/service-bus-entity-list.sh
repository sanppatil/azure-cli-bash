
SUBSCRIPTION=$1
RESOURCE_GROUP=$2
NAMESPACE=$3

echo "az account set --subscription '$SUBSCRIPTION'" | bash

function _getJsonValue() {
    echo ${1} | base64 --decode | jq -r ${2}
}

function printHeader {
    echo "EntityType|EntityName|SubscriptionName|AccessedAt|UpdatedAt|SubscriptionCount|RequiresSession" > results.csv
}

function printTopic {
    echo "Topic|$(_getJsonValue $1 '.name')|NA|$(_getJsonValue $1 '.accessedAt')|$(_getJsonValue $1 '.updatedAt')|$(_getJsonValue $topic '.subscriptionCount')|NA" >> results.csv
}

function printQueue {
    echo "Queue|$(_getJsonValue $1 '.name')|NA|$(_getJsonValue $1 '.accessedAt')|$(_getJsonValue $1 '.updatedAt')|NA|$(_getJsonValue $1 '.requiresSession')" >> results.csv
}

function printSubscription {
    echo "Subscription|$(_getJsonValue $1 '.name')|$(_getJsonValue $2 '.name')|$(_getJsonValue $2 '.accessedAt')|$(_getJsonValue $2 '.updatedAt')|NA|$(_getJsonValue $2 '.requiresSession')" >> results.csv
}

echo "Export started..."
printHeader
jsonTopicList=$(az servicebus topic list --resource-group $RESOURCE_GROUP --namespace-name $NAMESPACE --output json)
for topic in $(echo "${jsonTopicList}" | jq -r '.[] | @base64'); 
do
    printTopic $topic
    topicName=$(_getJsonValue $topic '.name')
    if [ $(_getJsonValue $topic '.subscriptionCount') -ne "0" ]
    then
        jsonSubscriptionList=$(az servicebus topic subscription list --resource-group $RESOURCE_GROUP --namespace-name $NAMESPACE --topic-name $topicName --output json)
        for subscription in $(echo "${jsonSubscriptionList}" | jq -r '.[] | @base64'); 
        do
            printSubscription $topic $subscription
        done
    fi
    echo -n "."
done
echo
jsonQueueList=$(az servicebus queue list --resource-group $RESOURCE_GROUP --namespace-name $NAMESPACE --output json)
for queue in $(echo "${jsonQueueList}" | jq -r '.[] | @base64'); 
do
    printQueue $queue
done
echo "Export completed..."
