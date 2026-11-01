input=$1
output=$2

awk '/^HETATM/ {
    printf("%-6s%5s   %-3s%-2s%-5s%8s%8s%8s%6s%6s%s\n", substr($0,1,6), substr($0,7,5), substr($0,12,3), substr($0,15,2), substr($0,17,5), substr($0,22,8), substr($0,30,8), substr($0,38,8), substr($0,46,6), substr($0,52,6), substr($0,58))
} /^ATOM/ {
    print
}' $1 > $2

