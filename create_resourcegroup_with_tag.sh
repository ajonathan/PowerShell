# Creates a resource group with a tag
# Example: .\create_resourcegroup_with_tag.sh -g myrg

# Variables to be set when creating the resource group
location="westeurope"
tagname="RemoveResourceGroup"
tagvalue="Yes"

# input section
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -g|--resourcegroup)
    rg="$2"
    shift
    shift
    ;;
    -h|--help)
    echo "Please add -g for Resource Group Name" >&2; exit 1
    ;;
    -*) echo "unknown option: $1" >&2; exit 1;;
    *) handle_argument "$1"; shift 1;;
esac
done

if [ "$rg" == "" ]
    then
        echo "Missing argument Resource Group Name"
        exit 1
fi

az group create -n "$rg" -l "$location" --tag "$tagname"="$tagvalue"