printf "\n\e[32m[*] Updating Javascript Helper Functions ...\e[0m\n"

# branch
export BRANCH=dev
# clone nuclei
git clone -b $BRANCH https://github.com/projectdiscovery/nuclei.git


# change directory
cd nuclei 

# generate documentation
printf "\n\e[32m[*] Generating DSL File ...\e[0m\n"
# generate typescript files
make dsl-docs
cd .. # change directory to root

# copy typescript files
printf "\n\e[32m[*] Copying DSL File...\e[0m\n"
mv  nuclei/dsl.md ../../templates/reference/js-helper-functions.mdx

# remove nuclei
printf "\n\e[32m[*] Cleanup ...\e[0m\n"
rm -rf nuclei

# done
printf "\n\e[32m[*] Done\e[0m\n"
