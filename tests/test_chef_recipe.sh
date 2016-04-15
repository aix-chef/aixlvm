#!/bin/sh

export PATH=$PATH:/opt/chef/bin

current_dir=$PWD
if [ ! -d "$current_dir/aixlvm/tests/recipes" ]
then
    echo "*** tests for cookbook aixlvm not found! ***"
    exit 1
fi

cd $current_dir

echo "--------- Run unittest for LVM -----------"
/opt/chef/embedded/bin/ruby $current_dir/aixlvm/tests/unittests/ts_all.rb
if [ $? -ne 0 ]
then
	echo "*** Unittest failure ****"
	exit 1
fi

echo "--------- Prepare tests cookbook ---------"
rm -rf $current_dir/aixlvm/recipes
cp -r $current_dir/aixlvm/tests/recipes $current_dir/aixlvm/recipes
echo "cookbook_path \"$current_dir\"" > $current_dir/solo.rb
echo "{\n\"run_list\": [ \"recipe[aixlvm]\" ]}" > $current_dir/firstrun.json

echo "--------- Initial LVM for test -----------"


echo "--------- Run test cookbool --------------"
chef-solo -c $current_dir/solo.rb -j $current_dir/firstrun.json

echo "--------- Check LVM ----------------------"

echo "--------- Clean --------------------------"
rm -rf $current_dir/aixlvm/recipes

