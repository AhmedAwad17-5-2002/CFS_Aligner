#include <iostream>
#include <cmath>
#include <string>
#include <stdio.h>
#include "svdpi.h"
#include "uvm_dpi.h"

using namespace std;


int unsigned APB_MAX_DATA_WIDTH;
int unsigned APB_MAX_ADDR_WIDTH;
int unsigned DATA_WIDTH;


extern "C" int parameter_check (string* path = "", int unsigned exp_value = 0){
 	return 0;
}

extern "C" int set_parameters (int x =0){
  	return 0;
}