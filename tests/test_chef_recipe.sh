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
rm -rf $current_dir/aixtest
mkdir -p $current_dir/aixtest
cp -r $current_dir/aixlvm/tests/recipes $current_dir/aixtest/recipes
echo "name             'aixtest'\ndepends   'aixlvm'\nsupports 'aix', '>= 6.1'\n" > $current_dir/aixtest/metadata.rb
echo "cookbook_path \"$current_dir\"" > $current_dir/solo.rb
echo "{\n\"run_list\": [ \"recipe[aixtest]\" ]\n}\n" > $current_dir/firstrun.json

echo "--------- Initial LVM for test -----------"
varyoffvg datavg 2>/dev/null
exportvg datavg 2>/dev/null
disks=$(echo $(lspv | grep 'None' | sed 's|\(hdisk[0-9]*\).*|\1|g'))
if [ "$disks" != "hdisk1 hdisk2 hdisk3 hdisk4" ]
then
	lspv
	echo "*** Bad initial disk status ****"
	exit 1
fi

echo "--------- Run test cookbool --------------"
chef-solo -c $current_dir/solo.rb -j $current_dir/firstrun.json
if [ $? -ne 0 ]
then
	echo "*** Cookbool failure ****"
	exit 1
fi

echo "--------- Check LVM ----------------------"
pp_size=$(lsvg datavg 2>/dev/null | grep 'PP SIZE' | sed 's|.* \([0-9]*\) mega.*|\1|g')
disk_datavg=$(echo $(lspv | grep 'datavg' | sed 's|\(hdisk[0-9]*\).*|\1|g'))
if [ $pp_size -ne 64 ]
then
	echo "pp_size=$pp_size" 
	lspv
	echo "*** Bad final status ****"
	exit 1
fi
if [ "$disk_datavg" != "hdisk1 hdisk2" ]
then
	echo "disk=$disk_datavg"
	lspv
	echo "*** Bad final status ****"
	exit 1
fi

echo "====== SUCCESS ====== "

echo "--------- Clean --------------------------"
rm -rf $current_dir/aixtest
rm -rf $current_dir/solo.rb $current_dir/firstrun.json

