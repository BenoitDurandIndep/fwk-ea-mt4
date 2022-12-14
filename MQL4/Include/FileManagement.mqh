//+------------------------------------------------------------------+
//|                                            FileManagement.mqh |
//|                                                    Benoit Durand |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property link      "http://www.mql4.com"
#property strict

#include <EASupport.mqh>
#include <Conversions.mqh>

//+------------------------------------------------------------------+
//| list of functions                                                |
//+------------------------------------------------------------------+
// getFileName : returns a normalzied name of a file with prefix, suffix and timestamp
// getFileNameGlobal : returns the file name without date
// openCSVFile : opens a csv file in read write, returns the handle
// openCSVReadFile : opens a csv file in read, returns the handle
// openTXTWriteFile : opens a text file in read write
// openTXTWriteFile : opens a text file in read
// writeHeaderOrderLog : writes the header for an order file
// writeOrderlog : writes the log for an order
// writeOpenlog : writes the log for an entry order
// writeCommentLog : writes a commentary log 
// writeCommentLine : writes a commentary line
// logMe : writes a log and print it 
// seekScenario : seeks a specific scenario in the backtest file
// getOpenSL : search the initial SL for an input order
// parseCommandOrderFile TODO : parses a command file to execute an order
// parseCommandBiaisFile TODO : parses a command biais file



//+------------------------------------------------------------------+
//| getFileName : returns a normalzied name of a file with prefix, suffix and timestamp
//+------------------------------------------------------------------+
string getFileName(string prefix,string suffix)
  {
   string myName="";
   MqlDateTime maDate;
   TimeToStruct(TimeLocal(),maDate);

   myName=prefix+"_"+Symbol()+"_"+Period()+"_"+maDate.year+StringLeftPad(maDate.mon,2,"0")+StringLeftPad(maDate.day,2,"0")+"-"+StringLeftPad(maDate.hour,2,"0")+StringLeftPad(maDate.min,2,"0")+StringLeftPad(maDate.sec,2,"0")+suffix;
   return myName;
  }

//+------------------------------------------------------------------+
//| getFileNameGlobal : returns the file name without date           |
//+------------------------------------------------------------------+
string getFileNameGlobal(string prefix,string suffix)
  {
   return prefix+"_"+Symbol()+"_"+suffix;
  }

//+------------------------------------------------------------------+
//| openCSVFile : opens a csv file in read write, returns the handle |
//+------------------------------------------------------------------+
int openCSVFile(string name, bool bypass=false)
  {
   int handle=-1;
   if(!bypass)
     {
      handle=FileOpen(name,FILE_CSV|FILE_SHARE_READ|FILE_WRITE);
      if(handle<0)
        {
         Print("File "+name+" not found, the last error is "+Fun_Error(GetLastError()));
         return(false);
        }
      else
        {
         Print(""+name+" open");
        }
     }
   else
     {
      return(-1);
     }
   return(handle);
  }

//+------------------------------------------------------------------+
//| openCSVFile : opens a csv file in read, returns the handle       |
//+------------------------------------------------------------------+
int openCSVReadFile(string name)
  {
   int handle=FileOpen(name,FILE_CSV|FILE_SHARE_READ);
   if(handle<0)
     {
      Print("File "+name+" not found, the last error is "+Fun_Error(GetLastError()));
      return(false);
     }
   else
     {
      Print(""+name+" open");
     }
   return(handle);
  }

//+------------------------------------------------------------------+
//| openTXTWriteFile : opens a text file in read write               |
//+------------------------------------------------------------------+
int openTXTWriteFile(string name, bool bypass=false)
  {
   int handle=-1;
   if(!bypass)
     {
      handle=FileOpen(name,FILE_TXT|FILE_READ|FILE_SHARE_READ|FILE_WRITE);
      if(handle<1)
        {
         Print("File "+name+" not found, the last error is "+Fun_Error(GetLastError()));
         return(false);
        }
      else
        {
         Print(""+name+" open");
        }
     }
   else
     {
      return(-1);
     }
   return(handle);
  }

//+------------------------------------------------------------------+
//| openTXTReadFile : opens a text file in read                     |
//+------------------------------------------------------------------+
int openTXTReadFile(string name)
  {
   int handle=FileOpen(name,FILE_TXT|FILE_SHARE_READ);
   if(handle<1)
     {
      Print("File "+name+" not found, the last error is "+Fun_Error(GetLastError()));
      return(false);
     }
   else
     {
      Print(""+name+" open");
     }
   return(handle);
  }

//+------------------------------------------------------------------+
//| writeHeaderOrderLog : writes the header for an order file        |
//| cS = separator                                                   |
//+------------------------------------------------------------------+
int writeHeaderOrderLog(int handle,string cS,int debugMode)
  {

   string headerOrder="DateHeure"+cS+"Id"+cS+"Magic"+cS+"Ordre"+cS+"Symbol"+cS+"Price"+cS+"Open"+cS+"SL"+cS+"Risque"+cS+"TP"+cS+"Ratio"+cS+"Lot"+cS+"Spread"+cS+"Comment";
   int err=FileWrite(handle,headerOrder);
   FileFlush(handle);
   if(err==0)
     {
      writeCommentLog(handle,9,"Error writing the header.",debugMode);
     }
   return 1;
  }

//+------------------------------------------------------------------+
//| writeOrderlog : writes the log for an order                      |
//| in input : all the info needed                                   |
//+------------------------------------------------------------------+
int writeOrderlog(int handle,int debugMode, int id, string ordre,string symbol,int magic,double price,double open,double sl,double tp,double risque,double ratio,double lot,int spread,string comment, int hCom)
  {
   string time=TimeToString(TimeLocal(),TIME_DATE)+" "+TimeToString(TimeLocal(),TIME_SECONDS);

   int err=FileWrite(handle,time,id,magic,ordre,symbol,price,open,sl,risque,tp,ratio,lot,spread,comment);
   FileFlush(handle);
   if(err==0)
     {
      writeCommentLog(hCom,9,"Error writing the order "+ordre+" "+symbol+" "+price+" !");
      Sleep(100);
      err=FileWrite(handle,time,id,magic,ordre,symbol,price,open,sl,risque,tp,ratio,lot,spread,comment);
      FileFlush(handle);
      if(err==0)
        {
         writeCommentLog(hCom,9,"Error writing the order 2nd try "+ordre+" "+symbol+" "+price+" !");
        }

     }
   if(debugMode>0)
     {
      writeCommentLog(hCom,5,"Order : "+id+" "+ordre+" "+symbol+" PRICE "+price+" OPEN "+open+" SL "+sl+" RISK "+risque+" TP "+tp+" RATIO "+ratio+":1 LOT "+lot+" SPREAD "+spread+" COMMENT "+comment,debugMode);
     }
   return err;
  }

//+------------------------------------------------------------------+
//| writeOpenlog : writes the log for an entry order                 |
//| in input : all the info needed                                   |
//+------------------------------------------------------------------+
int writeOpenlog(int handle,int debugMode, int id, string ordre,string symbol,int magic,double price,double open,double sl,int hCom)
  {
   string time=TimeToString(TimeLocal(),TIME_DATE)+" "+TimeToString(TimeLocal(),TIME_SECONDS);

   int err=FileWrite(handle,""); // Writesan empty line because at the opening of an existing file, the cursor is at the end of the last line
   if(err==0)
     {
      writeCommentLog(hCom,9,"Error writing the empty line !");   
     }

   err=FileWrite(handle,time+";"+id+";"+magic+";"+ordre+";"+symbol+";"+price+";"+open+";"+sl);
   FileFlush(handle);
   if(err==0)
     {
      writeCommentLog(hCom,9,"Error writing the entry "+ordre+" "+symbol+" "+price+" !");
      Sleep(100);
      err=FileWrite(handle,"");
      err=FileWrite(handle,time,id,magic,ordre,symbol,price,open,sl);
      FileFlush(handle);
      if(err==0)
        {
         writeCommentLog(hCom,9,"Error writing the entry 2nd try "+ordre+" "+symbol+" "+price+" !");
        }

     }
   return err;
  }

//+------------------------------------------------------------------+
//| writeCommentLog : writes a commentary log                        |
//| in input : file handle, the priority of the comment, the comment |
//| priority : 1 useless debug, 2 indic info, 3 warning and init,    |
//| 5 order management, 9 error !                                    |
//+------------------------------------------------------------------+
int writeCommentLog(int handle,int priorite,string comment,int debugMode=0)
  {
   string time=TimeToString(TimeLocal(),TIME_DATE)+" "+TimeToString(TimeLocal(),TIME_SECONDS);
   int err=FileWrite(handle,time,priorite, comment);
   FileFlush(handle);
   if(err==0)
     {
      Print("Error writing the comment "+ Fun_Error(GetLastError()));
      Sleep(100);
      err=FileWrite(handle,time,priorite, comment);
      FileFlush(handle);
      if(err==0)
        {
         Print("Error writing the comment 2nd try !!");
        }
     }
   if(debugMode>0)
     {
      Print("Comment : "+comment);
     }
   return 1;
  }

//+------------------------------------------------------------------+
//| writeCommentLine : writes a commentary line                      |
//+------------------------------------------------------------------+
int writeCommentLine(int handle,string comment,int debugMode=0)
  {
   int err=FileWrite(handle,comment);
   FileFlush(handle);
   if(err==0)
     {
      Print("Error writing the comment line "+ Fun_Error(GetLastError()));
     }
   if(debugMode>0)
     {
      Print("Comment : "+comment);
     }
   return 1;
  }


//+------------------------------------------------------------------+
//| logMe : writes a log and print it                                |
//| priority : 1 useless debug, 2 indic info, 3 warning and init,    |
//| 5 order management, 9 error !                                    |
//+------------------------------------------------------------------+
int logMe(int handle,int priorite,string comment,int debugMode=0)
  {
   if(handle>0)
     {
      writeCommentLog(handle,priorite,comment,debugMode);
     }
   else
     {
      Print(comment);
     }
   return 1;
  }

//+------------------------------------------------------------------+
//| seekScenario : seeks a specific scenario in the backtest file    |
//| input the number of the scenario                                 |
//| output an array with the parameters                              |                             
//+------------------------------------------------------------------+
bool seekScenario(int handle,int scenario,string& maLigne[],int handleCom)
  {
   string str="";
   int k=0,out=0;

   while(!FileIsEnding(handle) && out<1) 
     {
      //--- read the string
      str=FileReadString(handle);
      k=StringSplit(str,StringGetCharacter(";",0),maLigne);
      if(k>0)
        {
         if(IsInteger(maLigne[0]))
           {
            if(StrToInteger(maLigne[0])==scenario)
              {
               out=10; // exit loop
              }
           }
        }
     }

   if(out==0)
     {
      logMe(handleCom,0,"ERROR BACKTEST FILE SCENARIO "+scenario+" NOT FOUND !!!",1);
      ArrayFree(maLigne);
      return false;
     }
   return true;
  }


//+------------------------------------------------------------------+
//| getOpenSL : search the initial SL for an input order             |
//| in : the file's name, the order number, handle of file logs      |
//+------------------------------------------------------------------+
double getOpenSL(int handleOpen,int orderNum,int handleCom)
  {
   string str="";
   int k=0,out=0, handleTmp;
   double valSL=0.0;
   string maLigne[11];

   if(handleOpen<0)
     {
      logMe(handleCom,0," ERRROR HANDLE OPEN ! "+GetLastError(),1);
     }
   else   
     {
      FileSeek(handleOpen,0, SEEK_SET);
      while(!FileIsEnding(handleOpen) && out<1)
        {
         //--- read the string
         str=FileReadString(handleOpen);
         if(GetLastError()>0)
           {
            out=0;
           }
         if(StringLen(str)>1) // avoid empty lines
           {
            k=StringSplit(str,StringGetCharacter(";",0),maLigne);
            if(k>=7)
              {
               if(IsInteger(maLigne[1]))
                 {
                  if(StrToInteger(maLigne[1])==orderNum)
                    {
                     if(IsNumber(maLigne[7]))
                       {
                        valSL=StrToDouble(maLigne[7]);
                       }
                     out=10; // exit loop
                    }
                 }
              }
           }
        }//end while
     }

   if(out==0)
     {
      logMe(handleCom,0,"ERROR OPEN SL NOT FOUND ORDRE NUM "+orderNum+" !!",1);
     }
   FileSeek(handleOpen,0, SEEK_END);
   return valSL;
  }


//+------------------------------------------------------------------+
//| parseCommandOrderFile TODO : parses a command file to execute an order
//| command must be trade_id =  command                              |
//| ex : 999=BE$TP1:1.32:50%$TP2:1.40:50%                            |
//| myLine is a 2d array                                             |
//+------------------------------------------------------------------+
bool parseCommandOrderFile(const int handle,const string delim,string& myLine[][],const int handleCom)
  {
   int i=0,k=0;
   string str="";
   string ligneTemp[];

   while(!FileIsEnding(handle))
     {
      str=FileReadString(handle); 
      k=StringSplit(str,StringGetCharacter(delim,0),ligneTemp);
      if(k>1)
        {
         myLine[i][0]=ligneTemp[0];
         myLine[i][1]=ligneTemp[1];
        }
      else
        {
         logMe(handleCom,0,"ERROR COMMAND FILE NOT FOUND !!!",1);
        }
      i++;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| parseCommandBiaisFile TODO : parses a command biais file         |
//| command must be currency_pair$date_range$price_range$biais       |
//| ex : EURAUD$01/06/2020-31/08/2020$1.61-1.8$BUY                   |
//| myLine is a 2d array                                             |
//| output columns : 0=pair, 1=start date, 2=end date, 3=min price, 4=max_price, 5=order(1/-1)
//+------------------------------------------------------------------+
bool parseCommandBiaisFile(const string curr,const int handleConsFile,const string sep,string& myLine[][],const int handleCom)
  {
   int i=0,k=0,d=0,p=0;
   string str="",sepRange="-";
   string lineTemp[],dateRange[],pricRange[];
   bool res=false;

   while(!FileIsEnding(handleConsFile))
     {
      str=FileReadString(handleConsFile); 
      str=StringTrimRight(StringTrimLeft(str));
      k=StringSplit(str,StringGetCharacter(sep,0),lineTemp);
      if(k>1)
        {
         if(lineTemp[0]==curr)
           {
            d=StringSplit(lineTemp[1],StringGetCharacter(sepRange,0),dateRange);
            p=StringSplit(lineTemp[2],StringGetCharacter(sepRange,0),pricRange);
            if(d==2 && p==2)// ADD CONDITION ON DATE !!
              {
               myLine[i][0]=lineTemp[0];
               myLine[i][1]=dateRange[0];
               myLine[i][2]=dateRange[1];
               myLine[i][3]=pricRange[0];
               myLine[i][4]=pricRange[1];
               if(lineTemp[3]=="BUY")
                 {
                  myLine[i][5]="1";
                 }
               else
                 {
                  if(lineTemp[3]=="SELL")
                    {
                     myLine[i][5]="-1";
                    }
                 }
               res=true;
              }
           }
        }
      else
        {
         logMe(handleCom,0,"ERROR COMMAND FILE NOT FOUND !!!",1);
        }
      i++;
     }

   return res;
  }
//+------------------------------------------------------------------+
