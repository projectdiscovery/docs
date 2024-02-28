printf "\n\e[32m[*] Updating Nuclei Javascript Modules ...\e[0m\n"
# clone nuclei
git clone https://github.com/projectdiscovery/nuclei.git
# branch
export BRANCH=dev

# change directory
cd nuclei 
# checkout to branch
git checkout $BRANCH

# generate documentation
printf "\n\e[32m[*] Generating Typescript Files ...\e[0m\n"
# generate typescript files
make ts
cd .. # change directory to root

# copy typescript files
printf "\n\e[32m[*] Copying Typescript Files ...\e[0m\n"
cp -r nuclei/pkg/js/generated/ts src

# setup typescript project
printf "\n\e[32m[*] Download Typescript project dependencies ...\e[0m\n"
npm install

# run npm run build
printf "\n\e[32m[*] Building Nuclei Typescript Modules ...\e[0m\n"
npm run build

# generate docs
printf "\n\e[32m[*] Generate documentation ...\e[0m\n"
npm run docs


# post processing (rename .md to .mdx and remove .md in links)
printf "\n\e[32m[*] Post Processing ...\e[0m\n"

# rename .md to .mdx
cd docs
printf "\n\e[32m[*] Change extension from .md to .mdx ...\e[0m\n"
for file in *.md; do mv "$file" "${file%.md}.mdx"; done

# remove .md in links
printf "\n\e[32m[*] Remove .md in links ...\e[0m\n"
sed -i 's/\.md//g' *.mdx

# move to appropriate directory
cd ../../.. #project root
mv static/docsbuilder/docs/* templates/protocols/javascript/modules/

# remove nuclei
printf "\n\e[32m[*] Cleanup ...\e[0m\n"
rm -rf static/docsbuilder/nuclei
rm -rf static/docsbuilder/docs
rm -rf static/docsbuilder/src
rm -rf static/docsbuilder/node_modules

# done
printf "\n\e[32m[*] Done\e[0m\n"
