#include <iostream>
using namespace std;
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fstream>

// wget "http://www.google.com/search?q=jianxiong+xiao&hl=en&biw=2510&bih=1488&tbm=isch&ijn=sbg&start=0"  --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" -O x979.html

const char* queryFormat = "wget --tries=2 --timeout=5 \"http://www.google.com/search?q=%s&hl=en&biw=2510&bih=1488&tbm=isch&ijn=sbg&start=%d\" --user-agent=\"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6\" -O \"%s\"";

const char* text2match = "Our systems have detected unusual traffic from your computer network";

int FileSize(const char* sFileName)
{
  std::ifstream f;
  f.open(sFileName, std::ios_base::binary | std::ios_base::in);
  if (!f.good() || f.eof() || !f.is_open()) { return 0; }
  f.seekg(0, std::ios_base::beg);
  std::ifstream::pos_type begin_pos = f.tellg();
  f.seekg(0, std::ios_base::end);
  return static_cast<int>(f.tellg() - begin_pos);
}


void replaceChar(char* str,char cFrom, char cTo){
  for(int i=0;i<strlen(str);i++){
    if (str[i]==cFrom){
      str[i]=cTo;
    }
  }
}

bool isEmptyFile(const char* fname){
  return (FileSize(fname)==0);
}


int main(int argc, char** argv){
  if (argc!=3){
    return 1;
  }

  char* keywords = argv[1];
  char* pathname = argv[2];
  char dKeywords[1024*16];
  strcpy(dKeywords, keywords);
  replaceChar(dKeywords,'/','_');


  int si=0;
  while(true){
    if (si==1000){
      break;
    }else if (si > 979){
      si = 979;
    }

    char fname[1024*16];
    char cmd  [1024*16];
    sprintf(fname, "%s%s.%.3d.google", pathname, dKeywords, si);

    sprintf(cmd, queryFormat, keywords, si, fname);
    cout<<cmd<<endl;
    
    bool wgetSucceed;
    int waitTime = 60;
    for (int t=0;t<100;t++){
      wgetSucceed = (system(cmd)==0);

      if (wgetSucceed && !isEmptyFile(fname)){
	// open the file, make sure the file doesn't contain "detected unusual traffic from your network"

	ifstream f (fname);
	string s;
	string t;
	while (getline(f,t))
	  s += t + '\n';
	f.close();

	if ( s.find( text2match, 0 ) != string::npos ){
	  cout<<"Google block this ip address"<<endl;
	  cout<<"Current command:"<<endl;
	  cout<<cmd<<endl;
	  cout<<"waiting for resolving this issue manually, enter 'g' to continue > "<<endl;
	  while(1){
	    if ('g' == getchar())
	      break;
	  }
	}
      }

      if (wgetSucceed)
	break;
      else{
	//ip get blocked
	sleep(waitTime);
	waitTime *= 2;
      }
    }

    
    if (wgetSucceed)	wgetSucceed = ! isEmptyFile(fname); 

    if (!wgetSucceed){
      // remove file and break
      remove(fname);

      break;
    }

    si += 21;

    sleep(3); // <- avoid query too fast
  }
  //sleep(20);

  return 0;
}
