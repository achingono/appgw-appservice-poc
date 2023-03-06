while getopts n:l:c: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LOCATION=${OPTARG};;
        c) CODE=${OPTARG};;
    esac
done

if [ "$NAME" == "" ] || [ "$LOCATION" == "" ] || [ "$CODE" == "" ]; then
 echo "Syntax: $0 -n <name> -l <location> -c <unique code>"
 exit 1;
elif [[ $CODE =~ [^a-zA-Z0-9] ]]; then
 echo "Unique code must contain ONLY letters and numbers. No special characters."
 echo "Syntax: $0 -n <name> -l <location> -c <unique code>"
 exit 1;
fi

# provision infrastructure
az deployment sub create \
    --name $NAME \
    --location $LOCATION \
    --template-file ./iac/main.bicep \
    --parameters name=$NAME \
    --parameters location=$LOCATION \
    --parameters uniqueSuffix=$CODE
