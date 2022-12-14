//+------------------------------------------------------------------+
//|                                                  Conversions.mqh |
//|                                                    Benoit Durand |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property link      "http://www.mql4.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
#include <EASupport.mqh>
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| list of functions                                                |
//+------------------------------------------------------------------+
// ConvertPeriodStrToInt : converts a period from string to int ex: M15 -> 15
// IsInteger : checks if the string an integer
// IsNumber : checks if the string an number
// IsBool : checks if the string a boolean
// StringToBool : converts string a boolean
// getDateString : returns a date with time in option
// StringRepeat : Repeats the string STR N times
// StringLeftPad : Prepends occurrences of the string STR2 to the string STR to make a string N characters long 


//+------------------------------------------------------------------+
//|   converts a period from string to int ex: M15 -> 15             |
//+------------------------------------------------------------------+
int ConvertPeriodStrToInt(const string hPer)
  {

   int perInt=0;
   if(hPer=="CURRENT")
     {
      perInt=0;
     }
   if(hPer== "M1")
     {
      perInt=1;
     }
   if(hPer== "M5")
     {
      perInt=5;
     }
   if(hPer== "M15")
     {
      perInt=15;
     }
   if(hPer== "M30")
     {
      perInt=30;
     }
   if(hPer== "H1")
     {
      perInt=60;
     }
   if(hPer== "H4")
     {
      perInt=240;
     }
   if(hPer== "D1")
     {
      perInt=1440;
     }
   if(hPer== "W1")
     {
      perInt=10080;
     }
   if(hPer== "MN1")
     {
      perInt=43200;
     }

   return perInt;
  }

//+------------------------------------------------------------------+
//|   checks if the string an integer                                |
//+------------------------------------------------------------------+
bool IsInteger(string s)
  {
   for(int iPos = StringLen(s) - 1; iPos >= 0; iPos--)
     {
      int c = StringGetCharacter(s, iPos);

      if(c<'0' || c>'9')
        {
         if(c!='-')
           {
            return false;
           }
        }
     }
   return true;
  }


//+------------------------------------------------------------------+
//|   checks if the string an number                                 |
//+------------------------------------------------------------------+
bool IsNumber(string s)
  {
   for(int iPos = StringLen(s) - 1; iPos >= 0; iPos--)
     {
      int c = StringGetCharacter(s, iPos);

      if(c < '0' || c > '9')
        {
         if(c!='-' && c!='.')
           {
            return false;
           }

        }
     }
   return true;
  }


//+------------------------------------------------------------------+
//|   checks if the string a boolean                                 |
//+------------------------------------------------------------------+
bool IsBool(string s)
  {
   string l=StringToLower(s);
   if(s=="true" || s=="false")
     {
      return true;
     }
   else
     {
      return false;
     }
  }


//+------------------------------------------------------------------+
//|  converts string a boolean                                       |
//+------------------------------------------------------------------+
bool StringToBool(string s)
  {
   string l=StringToLower(s);

   if(s=="true")
     {
      return true;
     }
   else
     {
      return false;
     }
  }

//+------------------------------------------------------------------+
//| returns a date with time in option                               |
//| time=false (default) : YYYYMMDD                                  |
//| time=true (default) : YYYYMMDDHHMISS                             |
//+------------------------------------------------------------------+
string getDateString(bool time=false)
  {

   string maDateGetDateString="";
   MqlDateTime maStrgetDateString;
   ushort uSepgetDateString=StringGetCharacter("0",0);
   TimeToStruct(TimeLocal(),maStrgetDateString);

   maDateGetDateString=maStrgetDateString.year+IntegerToString(maStrgetDateString.mon,2,uSepgetDateString)+IntegerToString(maStrgetDateString.day,2,uSepgetDateString);

   if(time)
     {
      maDateGetDateString+=IntegerToString(maStrgetDateString.hour,2,uSepgetDateString)+IntegerToString(maStrgetDateString.min,2,uSepgetDateString)+IntegerToString(maStrgetDateString.sec,2,uSepgetDateString);
     }

   return maDateGetDateString;

  }

//+------------------------------------------------------------------+
//| Repeats the string STR N times                                   |
//| Usage:    string x=StringRepeat("-",10)  returns x = "----------"|
//+------------------------------------------------------------------+
string StringRepeat(string str, int n=1)
  {
   string outstr = "";
   for(int i=0; i<n; i++)
     {
      outstr = outstr + str;
     }
   return(outstr);
  }


//+------------------------------------------------------------------+
//| Prepends occurrences of the string STR2 to the string STR        |
//| to make a string N characters long                               |
//| Usage: x=StringLeftPad("ABCDEFG",9," ")  returns x = "  ABCDEFG" |
//+------------------------------------------------------------------+
string StringLeftPad(string str, int n=1, string str2=" ")
  {
   return(StringRepeat(str2,n-StringLen(str)) + str);
  }
//+------------------------------------------------------------------+
