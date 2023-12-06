## jsdocs.sh - Generate SDK documentation from JSDoc comments

printf "[+] Clone projectdiscovery/nuclei\n"
git clone https://github.com/projectdiscovery/nuclei.git

TargetDir="templates/protocols/javascript/modules"

printf "[+] Create modules directory skip if exists\n"
mkdir -p $TargetDir

printf "[+] Convert Javascript files to Markdown (MDX)\n"
for i in $(find ./nuclei/pkg/js/generated/js/ -type f); do                                                             
  echo -e "processing $i"                      
  file=$(echo $i| rev | cut -d '/' -f 1 | rev | cut -d '.' -f 1)
  jsdoc2md -f $i > $TargetDir/$file.mdx
done

printf "[+] Attempting to fix some issues with the MDX files\n"

# replace all bytes~NewBuffer(call) with (bytes).NewBuffer(call)
find ./$TargetDir -type f -name "*.mdx" -exec perl -i -pe 's/(?<!\*\s)([a-zA-Z0-9_]+)~([a-zA-Z0-9_]+\([^)]*\))/($1).$2/g' {} +

# quote instead of ~
 find ./$TargetDir -type f -name "*.mdx" -exec perl -i -pe 's/\[\~([^]]+)\]/[`$1`]/g' {} +

# wrap global function definations
find ./$TargetDir -type f -exec perl -i -pe 's/# (\w+)~(\w+)/# \($1\).$2/g' {} +

# remove whitespace between end tags (seems like a bug in mdx parsing)
find ./$TargetDir -type f -exec perl -i -0777 -pe 's/<\/p>\s*<\/dd>/<\/p><\/dd>/gs' {} +

# quote all function calls
find ./$TargetDir -type f -exec perl -i -pe 's/\*\s\[\.(.+?)\]\(/\* [`.$1`]\(/g' {} +

printf "[+] Cleanup\n"
rm -rf nuclei

printf "[+] Done\n"

printf "[+] Validate following entries exist in javascript modules group in mint.json\n"

for i in $(find $TargetDir -type f | cut -d '.' -f 1 | sort); do
  printf "\"$i\",\n"
done
