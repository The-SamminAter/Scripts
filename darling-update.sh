#!/bin/bash
cd ~/Downloads/darling/
git pull
git submodule init
git submodule update
cd build
cmake ..
make -j4
sudo make -j4 install
make -j4 lkm
sudo make -j4 lkm_install
echo ""
echo "Done"
echo ""
