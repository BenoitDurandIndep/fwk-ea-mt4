//+------------------------------------------------------------------+
//|                                                    EASupport.mqh |
//|                                                    Benoit Durand |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property link      "http://www.mql4.com"
#property strict

// #import
#include <FileManagement.mqh>
#include <Conversions.mqh>
#include <MoneyManagement.mqh>
#include <APIIndicators.mqh>

//+------------------------------------------------------------------+
//| list of functions                                                |
//+------------------------------------------------------------------+
//|DeleteAll : Cancel all orders for a magic number, return 1 at the end
//|Verif : check parameters before sending an order
//|OrderModifyPreChecked : Check that values to be passed to the OrderModify()
//|sendOrder : send an order with retries
//|GoodTime : returns if it's a good period to trade
//|NbOrderOpen : returns nb open ordersfor this magic number
//|GetMagicNumber : returns the magic number based on a passed int, currency and period
//|sleepPeriode : sleep for a % of the period : ex 50 and chart is 4h = sleep for 2h
//|Fun_Error: returns error label
//|splitParam : splits an input string into an array
//|BubbleSort2D : Sorts a 2 dimension array by an index
//|getTrend : calculates the trend for a timeframe with indicators in input
//|getDeltaSL : Calculates the size of the SL, returns -1 if error
//|TrailingStop : updates the SL of the ticket
//|DisplayTextLeftCorner : Displays the text in the left corner of the graph
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   Cancel all orders for a magic number, return 1 at the end      |
//+------------------------------------------------------------------+
int DeleteAll(const int hmagic,const int hHandle=0,const int hdebugMode=0)
  {
   for(int i =OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==hmagic)
           {
            if(!OrderDelete(OrderTicket()))
              {
               if(hHandle>0)
                 {
                  writeCommentLog(hHandle,1,"OrderDelete error "+Fun_Error(GetLastError()),hdebugMode);
                 }
               else
                 {
                  Print("OrderDelete error ",Fun_Error(GetLastError()));
                 }
              }
            else
              {
               if(hHandle>0)
                 {
                  writeCommentLog(hHandle,1,"OrderDelete OK "+OrderTicket(),hdebugMode);
                 }
               else
                 {
                  Print("OrderDelete OK "+OrderTicket());
                 }
              }
           }
        }
     }
   return (1);
  }

//+------------------------------------------------------------------+
//|  check parameters before sending an order                        |
//+------------------------------------------------------------------+
void Verif(const double hminLot,const double hmaxLot,const double hdistMin,const double hstepLot,
           double hmonStop=0, double hmonLot=0, double hmonTrailing=0, double hmaLimite=0,const int hHandle=0,const int hdebugMode=0)
  {
   int digits;

   if(hstepLot==0.01)
     {
      digits=2;
     }
   else
     {
      digits=1;
     }
   hmonLot=NormalizeDouble(hmonLot,digits);

   if(hmonLot<hminLot && hmonLot>0)
     {
      if(hHandle>0)
        {
         writeCommentLog(hHandle,1,"Verif : Volume too low "+hminLot,hdebugMode);
        }
      else
        {
         Print("Volume too low "+hminLot);
        }


      hmonLot=NormalizeDouble(hminLot,digits);
     }

   if(hmonLot>hmaxLot && hmonLot>0)
     {
      if(hHandle>0)
        {
         writeCommentLog(hHandle,1,"Verif : Volume too high "+hmaxLot,hdebugMode);
        }
      else
        {
         Print("Volume too high "+hmaxLot);
        }
      hmonLot=NormalizeDouble(hmaxLot,digits);
     }

   if(hmonStop<hdistMin && hmonStop>0)
     {
      if(hHandle>0)
        {
         writeCommentLog(hHandle,1,"Verif : Stop too close "+hdistMin+" "+hmonStop,hdebugMode);
        }
      else
        {
         Print("Stop too close "+hdistMin+" "+hmonStop);
        }

      hmonStop=hdistMin+1;
     }
   if(hmaLimite<hdistMin && hmaLimite>0)
     {
      if(hHandle>0)
        {
         writeCommentLog(hHandle,1,"Verif : TP too close " +hdistMin+" "+hmaLimite,hdebugMode);
        }
      else
        {
         Print("TP too close " +hdistMin+" "+hmaLimite);
        }

      hmaLimite=hdistMin;
     }

   if(hmonTrailing<  0)
     {
      if(hHandle>0)
        {
         writeCommentLog(hHandle,1,"Verif : Trailing negative "+hmonTrailing,hdebugMode);
        }
      else
        {
         Print("Trailing negative "+hmonTrailing);
        }

      hmonTrailing=0;
     }
  }

//+------------------------------------------------------------------+
//| Function..: OrderModifyPreChecked                                |
//| Purpose...: Check that values to be passed to the OrderModify()  |
//|             function have changed and avoid error 1.             |
//| Parameters: Same as OrderModify()                                |
//| Returns...: bool Success.                                        |
//| Notes.....: The order must have been selected using OrderSelect()|
//| Sample....: if(OrderModifyPreChecked(...)) OrderModify(...);     |
//OrderModifyPreChecked()
//+------------------------------------------------------------------+
bool OrderModifyPreChecked(const int orderType, const double orderStopLoss,
                           const double orderTakeProfit, const double orderOpenPrice, const datetime orderExpiration,
                           const int iTicket,const double dPrice,const double dSL,const double dTP,
                           const datetime tExpire,const color cColor=CLR_NONE)
  {
   if(orderType<=OP_SELL && ((NormalizeDouble(orderStopLoss-dSL,8)!=0) || (NormalizeDouble(orderTakeProfit-dTP,8)!=0)))
     {
      return(true);
     }
   else
      if(orderType>OP_SELL && ((NormalizeDouble(orderStopLoss-dSL,8)!=0) || (NormalizeDouble(orderTakeProfit-dTP,8)!=0) || (NormalizeDouble(orderOpenPrice-dPrice,8)!=0) || (tExpire!=orderExpiration)))
        {
         return(true);
        }
   return(false);
  }

//sendOrder : send an order with retries
//returns 1 if ok else -1
//hMagic : magic number
//hsens : BUY or SELL
//hComment : comment to set in the order
//hSL : size of the SL
//hLot : size of the order
//hTP : size of the TP
//htabRes : pointer to the tab to calculate risks et other indicators
//hHandleCom : comments file
//hHandleOrder : orders file
//hdebugMode : debug mode
int sendOrder(const int hMagic,const string hsens,const string hComment, const double hSL, const double hLot, const double hTP,double &htabRes[],
              const int hHandleCom=0,const int hHandleOrder=0,const int hdebugMode=0,const int hHandleOpen=0)
  {
   int myRet=-1;//return
   int tryOrder=0; 
   int Ticket;
   double TP=0.0;

   logMe(hHandleCom,2,"Account Balance before = "+AccountBalance(),hdebugMode);

//check if SL is enough
   if(hSL<MarketInfo(Symbol(),MODE_STOPLEVEL)*Point)
     {
      logMe(hHandleCom,9,"Order rejected because SL is too thin, SL:"+hSL+" SL Min:"+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,hdebugMode);
     }
   else
     {
      if(hsens=="BUY" && hSL>0.0 && hLot>0.0)
        {
         //buy
         while(tryOrder<10) //10 tries
           {
            RefreshRates();

            TP=getFixeTP(hsens,hTP); // returns fix value of TP
            if(TP<=0.0)
              {
               TP=Ask+(1000*Point);//  +100p by default
              }

            Ticket=OrderSend(Symbol(),OP_BUY,hLot,Ask,5,Bid-(hSL),TP,hComment,hMagic);
            if(Ticket<=0)
              {
               logMe(hHandleCom,9,"Buy Error = "+GetLastError()+ " - "+Fun_Error(GetLastError()),hdebugMode);
               tryOrder++;// newt try
              }
            else
              {
               updateRisk(Ticket,htabRes);// updates risks and indicators
               writeOrderlog(hHandleOrder,hdebugMode,Ticket,"BUY "+hComment,Symbol(),hMagic,Ask,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit(),htabRes[2],htabRes[3],hLot,MarketInfo(Symbol(),MODE_SPREAD)," OK BUY "+hComment,hHandleCom);
               writeOpenlog(hHandleOpen,hdebugMode,Ticket,"BUY "+hComment,Symbol(),hMagic,Ask,OrderOpenPrice(),OrderStopLoss(),hHandleCom);
               logMe(hHandleCom,5,"Ticket="+Ticket+" Risk="+htabRes[2]+"%, Profit="+DoubleToStr(htabRes[0],2)+", Loss="+DoubleToStr(htabRes[1],2)+", "+htabRes[3]+":1",hdebugMode);
               logMe(hHandleCom,5,"Spread:"+MarketInfo(Symbol(), MODE_SPREAD)+" open:"+OrderOpenPrice()+" sl:"+OrderStopLoss()+" val pip :"+DoubleToStr(MarketInfo(Symbol(),MODE_TICKVALUE),5)+" bid:"+Bid+" Ask:"+Ask,hdebugMode);
               logMe(hHandleCom,2,"Account Balance after = "+AccountBalance(),hdebugMode);
               myRet=1;
               tryOrder=100;//ok get out the loop
              }
           }//end while
        }

      if(hsens=="SELL" && hSL>0.0 && hLot>0.0)
        {
         while(tryOrder<10)
           {
            RefreshRates();

            TP=getFixeTP(hsens,hTP); 
            if(TP<=0.0)
              {
               TP=Bid-(1000*Point);
              }

            Ticket=OrderSend(Symbol(),OP_SELL,hLot,Bid,5,Ask+(hSL),TP,hComment,hMagic);
            if(Ticket<=0)
              {
               logMe(hHandleCom,9,"Sell Error = "+GetLastError()+ " - "+Fun_Error(GetLastError()),hdebugMode);
               tryOrder++;

              }
            else    
              {
               updateRisk(Ticket,htabRes);

               writeOrderlog(hHandleOrder,hdebugMode,Ticket,"SELL "+hComment,Symbol(),hMagic,Ask,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit(),htabRes[2],htabRes[3],hLot,MarketInfo(Symbol(),MODE_SPREAD)," OK SELL "+hComment,hHandleCom);
               writeOpenlog(hHandleOpen,hdebugMode,Ticket,"SELL "+hComment,Symbol(),hMagic,Ask,OrderOpenPrice(),OrderStopLoss(),hHandleCom);
               logMe(hHandleCom,5,"Ticket="+Ticket+" Risk="+htabRes[2]+"%, Profit="+DoubleToStr(htabRes[0],0)+", Loss="+DoubleToStr(htabRes[1],0)+", "+htabRes[3]+":1",hdebugMode);
               logMe(hHandleCom,5,"Spread:"+MarketInfo(Symbol(), MODE_SPREAD)+" open:"+OrderOpenPrice()+" sl:"+OrderStopLoss()+" val pip :"+MarketInfo(Symbol(),MODE_TICKVALUE)+" bid:"+Bid+" Ask:"+Ask,hdebugMode);
               logMe(hHandleCom,2,"Account Balance after = "+AccountBalance(),hdebugMode);
               myRet=1;
               tryOrder=100; 
              }
           }//end while
        }
     }

   return myRet;
  }

//+------------------------------------------------------------------+
//|  returns if it's a good period to trade                          |
//|  hmode : 0 everytime, 1 accorind to time limit passed,           |
//|  2 according to the symbol market open hours                     |
//|  returns 1 if OK 0 if not OK                                     |
//+------------------------------------------------------------------+
int GoodTime(const int hmode,const string hparam1,const string hparam2)
  {
   int ret=-1;

   if(hmode==0)  // mode 0 tout le temps vrai
     {
      ret=1;
     }
//mode 1 input time
   if(hmode==1)
     {
      int deb=StringToInteger(hparam1);
      int fin=StringToInteger(hparam2);
      int hDeb=MathFloor(deb/100.0);
      int minDeb=MathMod(deb,100.0);
      int hFin=MathFloor(fin/100.0);
      int minFin=MathMod(fin,100.0);
      int tmpDeb=0,tmpFin=0,nowMin=0;

      if(hDeb>=0 && hDeb<23  && hFin>=0 && hFin<24
         && minDeb>=0 && minDeb<=59 && minFin>=0 && minFin<=59)
        {
         tmpDeb=hDeb*60+minDeb;
         tmpFin=hFin*60+minFin;
         nowMin=Hour()*60+Minute();

         if(nowMin>=tmpDeb && nowMin<=tmpFin)
           {
            ret=1;
           }
         else
           {
            ret=0;
           }
        }
     }

//mode 2 according yo the currency
   if(hmode==2)
     {
      if(Hour()>=8 && Hour()<21)
        {
         ret=1;
        }
      else  //for pacific AUD, JPY, NZD
        {
         if((hparam1=="AUD" || hparam2=="AUD") && Hour()>=0 && Hour()<7)
           {
            ret=1;
           }
         else
           {
            if((hparam1=="JPY" || hparam2=="JPY") && Hour()>=2 && Hour()<8)
              {
               ret=1;
              }
            else
              {
               if((hparam1=="NZD" || hparam2=="NZD") && (Hour()>=22 || Hour()<5))
                 {
                  ret=1;
                 }
               else
                 {
                  ret=0;
                 }
              }
           }
        }
     }
   return (ret);
  }


//+------------------------------------------------------------------+
//| returns nb open ordersfor this magic number                      |
//+------------------------------------------------------------------+
int NbOrderOpen(int const hmagic)
  {
   int nb=0;
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) 
        {
         if(OrderMagicNumber()==hmagic)
           {
            nb++;
           }
        }
     }
   return(nb);
  }

//+------------------------------------------------------------------+
//| returns the magic number based on a passed int, currency and period
//+------------------------------------------------------------------+
int GetMagicNumber(const int hbaseMagic,const int Per, const string symbolType="FOREX")
  {
   int newMagic=hbaseMagic;
   string symb=Symbol();

   if(symbolType=="FOREX")
     {
      string majeur=StringSubstr(symb,0,3);
      string mineur=StringSubstr(symb,3,3);

      if(majeur=="USD")
        {
         newMagic+=1000;
        }
      if(majeur=="EUR")
        {
         newMagic+=2000;
        }
      if(majeur=="CHF")
        {
         newMagic+=3000;
        }
      if(majeur=="GBP")
        {
         newMagic+=4000;
        }
      if(majeur=="JPY")
        {
         newMagic+=5000;
        }
      if(majeur=="CAD")
        {
         newMagic+=6000;
        }
      if(majeur=="AUD")
        {
         newMagic+=7000;
        }
      if(majeur=="NZD")
        {
         newMagic+=8000;
        }

      if(mineur=="USD")
        {
         newMagic+=100;
        }
      if(mineur=="EUR")
        {
         newMagic+=200;
        }
      if(mineur=="CHF")
        {
         newMagic+=300;
        }
      if(mineur=="GBP")
        {
         newMagic+=400;
        }
      if(mineur=="JPY")
        {
         newMagic+=500;
        }
      if(mineur=="CAD")
        {
         newMagic+=600;
        }
      if(mineur=="AUD")
        {
         newMagic+=700;
        }
      if(mineur=="NZD")
        {
         newMagic+=800;
        }
     }
   else
     {
      if(StringFind(symb,"FRA40")>0)
        {
         newMagic+=10100;
        }
      if(StringFind(symb,"GER30")>0)
        {
         newMagic+=10200;
        }
      if(StringFind(symb,"US100")>0)
        {
         newMagic+=10300;
        }
      if(StringFind(symb,"US500")>0)
        {
         newMagic+=10400;
        }
      if(StringFind(symb,"USOil")>0)
        {
         newMagic+=10500;
        }
      if(StringFind(symb,"France40")>0)
        {
         newMagic+=11100;
        }
      if(StringFind(symb,"Germany30")>0)
        {
         newMagic+=11200;
        }
      if(StringFind(symb,"USNDAQ100")>0)
        {
         newMagic+=11300;
        }
      if(StringFind(symb,"USSPX500")>0)
        {
         newMagic+=11400;
        }
      if(StringFind(symb,"WTI")>0)
        {
         newMagic+=12100;
        }
      if(StringFind(symb,"GOLD")>0)
        {
         newMagic+=12200;
        }
      if(StringFind(symb,"SILVER")>0)
        {
         newMagic+=12300;
        }
     }

   if(Per<61)
     {
      newMagic+=Per;  // si period<61min opn ajoute directe
     }

   switch(Per)
     {
      case 120 :
         newMagic+=65;
         break;
      case 180 :
         newMagic+=70;
         break;
      case 240 :
         newMagic+=75;
         break;
      case 360 :
         newMagic+=80;
         break;
      case 480 :
         newMagic+=85;
         break;
      case 720 :
         newMagic+=90;
         break;
      case 1440 :
         newMagic+=95;
         break;
     }

   Print("Magic ",newMagic);
   return(newMagic);

  }

//+------------------------------------------------------------------+
//| sleep for a % of the period : ex 50 and chart is 4h = sleep for 2h
//+------------------------------------------------------------------+
int sleepPeriode(int hCoef)
  {
   int maPer=Period();
   int monSl=1000*60*(hCoef/100)*maPer;
   Sleep(monSl);
   return monSl;
  }

//+------------------------------------------------------------------+
//| returns error label                                              |
//| error = the error code                                           |
//| sleepOn = have a break according the error                       |
//+------------------------------------------------------------------+
string Fun_Error(int error, bool sleepOn=true)
  {
   string myError="";
   switch(error)
     {
      case 0:// Not crucial errors
         myError="no error";
      case  4:
         myError="Trade server is busy. Trying once again..";
         if(sleepOn)
           {
            Sleep(3000);  // Simple solution
           }
      case 135:// Refresh rates
         myError="Price changed. Trying once again..";
         RefreshRates();
      case 136:
         myError="No prices. Waiting for a new tick..";
         while(RefreshRates()==false)           // Till a new tick
            Sleep(100);                           // Pause in the loop
      case 137:
         myError="Broker is busy. Trying once again..";
         Sleep(3000);                           // Simple solution
      case 146:
         myError="Trading subsystem is busy. Trying once again..";
         Sleep(500);                            // Simple solution
      // Critical errors
      case  2:
         myError="Common error.";
      case  5:
         myError="Old terminal version.";
      case 64:
         myError="Account blocked.";
      case 133:
         myError="Trading is disabled.";
      case 134:
         myError="Not enough money to execute operation.";
      default:
         myError="Error occurred: "+error;  // Other variants
     }
   return myError;
  }

//+------------------------------------------------------------------+
//| splitParam : splits an input string into an array                |
//| input : the string of inputs and the pointer to the array to fill|
//| returned tab is a matrix  arr[N][2]                              |
//+------------------------------------------------------------------+
void splitParam(const string paramEntree, string &tabSortie[][])
  {
   string tempSplitParamSL_1[],tempSplitParamSL_2[];

   if(StringSplit(paramEntree,StringGetCharacter("-",0),tempSplitParamSL_1)>1)
     {
      for(int i=0; i<ArraySize(tempSplitParamSL_1); i++)
        {
         if(StringSplit(tempSplitParamSL_1[i],StringGetCharacter(":",0),tempSplitParamSL_2)==2)
           {
            tabSortie[i][0]=tempSplitParamSL_2[0];
            tabSortie[i][1]=tempSplitParamSL_2[1];
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| BubbleSort2D : Sorts a 2 dimension array by an index             |
//| myArray : 2D array to sort, SortIndex : index column used by the sort, h_com : logs
//+------------------------------------------------------------------+
void BubbleSort2D(string &myArray[][], int SortIndex, int h_com)
  {

   int nblines = ArrayRange(myArray, 0);
   int nbcol = ArrayRange(myArray, 1);
   string tabTemp[];
   ArrayResize(tabTemp,nbcol,nbcol);
   bool tabTrie=true;
   logMe(h_com,0,"Buble sort nb lines "+nblines+" nb col "+nbcol);

   int liPosition;

   for(int i = 0; i < nblines; i++)
     {
      tabTrie=true;
      for(int j = 0; j < nblines; j++)
        {

         double vali=myArray[i][SortIndex],valj=myArray[j][SortIndex];

         if(vali > valj)
           {
            for(int k=0; k<nbcol; k++)
              {
               tabTemp[k]=myArray[i][k];
              }
            for(int k=0; k<nbcol; k++) 
              {
               myArray[i][k]=myArray[j][k];
               myArray[j][k]=tabTemp[k];
              }
            tabTrie=false;
           }
        }
     }
  }



//+------------------------------------------------------------------+
//| calculates the trend for a timeframe with indicators in input    |
//| mode : "1x2x3" / "1x2+3x4"                                       |
//| returns no use/up/down/neutral/ERROR                             |
//| WARN, put indicators with res_spe at the end                     |
//+------------------------------------------------------------------+
string getTrend(const string mode="", const int intPeriod_UT=0, const string indic_1="", const string indic_2="", const string indic_3="", const string indic_4="",const int hCom=-1)
  {
   double res_def=-9999, res_neutral=-5555,res_spe_vol=5555;
   double res_indic_1=res_def,res_indic_2=res_def,res_indic_3=res_def,res_indic_4=res_def;
   string res_trend="neutral";

   if(indic_1!="" && intPeriod_UT>0)
     {
      if(mode=="1x2x3")
        {
         res_indic_1=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_1,hCom);

         if(indic_2!="")
           {
            res_indic_2=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_2,hCom);

            if(indic_3!="")
              {
               res_indic_3=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_3,hCom);

               if((res_indic_1>0 || res_indic_1==res_neutral) && (res_indic_2>0 || res_indic_2==res_neutral) && res_indic_3>0)
                 {
                  res_trend="up";
                 }
               if((res_indic_1>0 || res_indic_1==res_neutral) && res_indic_2>0 && (res_indic_3>0 || res_indic_3==res_neutral))
                 {
                  res_trend="up";
                 }
               if(res_indic_1>0  && (res_indic_2>0 || res_indic_2==res_neutral) && (res_indic_3>0 || res_indic_3==res_neutral))
                 {
                  res_trend="up";
                 }
               if((res_indic_1<0 || res_indic_1==res_neutral) && (res_indic_2<0 || res_indic_2==res_neutral) && res_indic_3<0)
                 {
                  res_trend="down";
                 }
               if((res_indic_1<0 || res_indic_1==res_neutral) && res_indic_2<0 && (res_indic_3<0 || res_indic_3==res_neutral || res_indic_3==res_spe_vol))
                 {
                  res_trend="down";
                 }
               if(res_indic_1<0  && (res_indic_2<0 || res_indic_2==res_neutral) && (res_indic_3<0 || res_indic_3==res_neutral || res_indic_3==res_spe_vol))
                 {
                  res_trend="down";
                 }
               if(res_indic_1==res_neutral  && res_indic_2==res_neutral && (res_indic_3==res_neutral || res_indic_3==res_spe_vol))
                 {
                  res_trend="neutral";
                 }
              }
            else
              {
               if((res_indic_1>0 || res_indic_1==res_neutral) && res_indic_2>0)
                 {
                  res_trend="up";
                 }
               if(res_indic_1>0  && (res_indic_2>0 || res_indic_2==res_neutral))
                 {
                  res_trend="up";
                 }
               if((res_indic_1<0 || res_indic_1==res_neutral) && res_indic_2<0)
                 {
                  res_trend="down";
                 }
               if(res_indic_1<0  && (res_indic_2<0 || res_indic_2==res_neutral || res_indic_2==res_spe_vol))
                 {
                  res_trend="down";
                 }
               if(res_indic_1==res_neutral  && (res_indic_2==res_neutral || res_indic_2==res_spe_vol))
                 {
                  res_trend="neutral";
                 }
              }
           }
         else
           {
            if(res_indic_1>0)
              {
               res_trend="up";
              }
            if(res_indic_1<0)
              {
               res_trend="down";
              }
            if(res_indic_1==res_neutral || res_indic_1==res_spe_vol)
              {
               res_trend="neutral";
              }
           }
        }
      else
        {
         if(mode=="1x2+3x4")
           {
            string res_trend_12="neutral", res_trend_34="neutral";
            res_trend="neutral";

            res_indic_1=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_1,hCom);
            if(indic_2!="")
              {
               res_indic_2=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_2,hCom);
              }
            if(indic_3!="")
              {
               res_indic_3=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_3,hCom);
              }
            if(indic_4!="")
              {
               res_indic_4=getIndicatorFromParam(Symbol(), intPeriod_UT,indic_4,hCom);
              }

            if((res_indic_1>0 && (res_indic_2>0 || res_indic_2==res_def || res_indic_2==res_neutral)) || (res_indic_1==res_neutral && res_indic_2>0))
              {
               res_trend_12="up";
              }
            if((res_indic_1<0 && (res_indic_2<0 || res_indic_2==res_def || res_indic_2==res_neutral)) || (res_indic_1==res_neutral && res_indic_2<0))
              {
               res_trend_12="down";
              }
            if((res_indic_3>0 && (res_indic_4>0 || res_indic_4==res_def || res_indic_4==res_neutral)) || (res_indic_3==res_neutral && res_indic_4>0))
              {
               res_trend_34="up";
              }
            if((res_indic_3<0 && (res_indic_4<0 || res_indic_4==res_def || res_indic_4==res_neutral)) || (res_indic_3==res_neutral && res_indic_4<0))
              {
               res_trend_34="down";
              }
           }
         else
           {
            res_trend="ERROR";
           }
        }
     }
   else
     {
      res_trend="no use";
     }
   return res_trend;
  }


//+------------------------------------------------------------------+
//| Calculates the size of the SL, returns -1 if error               |
//| mode 0 : lowest for n bars : param1 nb of candles                |
//| mode 1 : function of ATR and coefficient : param1 : nb of candles for ATR , param2 : coef to multiply the ATR
//| mode 2 : function of an indicator in input, uses api             |
//+------------------------------------------------------------------+
double getDeltaSL(const string direction, const int period=PERIOD_H4, const int mode=0,const string param1="10",const double param2=0.0, const int hCom=-1)
  {
   double valSL=-1.0,tmpVal=0.0;
   int myParam1=0, f_Debug_Mode=1;

   if(mode==0 || mode==1)
     {
      if(IsInteger(param1))
        {
         myParam1=StringToInteger(param1);
        }
      else
        {
         logMe(hCom,9,"getDeltaSL ERROR CONV param1="+param1,f_Debug_Mode);
         return valSL;
        }
     }

   if(direction=="BUY")
     {
      if(mode==0)
        {
         tmpVal=iLow(Symbol(),period,iLowest(Symbol(),period,MODE_LOW,myParam1,1));
         valSL=Bid-tmpVal;
        }
      if(mode==1)
        {
         tmpVal=iATR(Symbol(),period,myParam1,1);
         valSL=NormalizeDouble((tmpVal*param2),5);
        }
      if(mode==2)
        {
         tmpVal=getIndicatorFromParam(Symbol(), period,param1,hCom);
         valSL=Bid-tmpVal;
        }
     }
   else
     {
      if(mode==0)
        {
         tmpVal=iHigh(Symbol(),period,iHighest(Symbol(),period,MODE_HIGH,myParam1,1));
         valSL=(tmpVal+MarketInfo(Symbol(),MODE_SPREAD)*Point)-Ask;
        }
      if(mode==1)
        {
         tmpVal=iATR(Symbol(),period,myParam1,1);
         valSL=NormalizeDouble((tmpVal*param2),5);
        }
      if(mode==2)
        {
         tmpVal=getIndicatorFromParam(Symbol(), period,param1,hCom);
         valSL=(tmpVal+MarketInfo(Symbol(),MODE_SPREAD)*Point)-Ask;
        }
     }
   return(valSL);
  }

//+------------------------------------------------------------------+
//| trailing stop, updates the SL of the ticket                      |
//| hticket = the ticket to update                                   |
//| monTrailing=distance if we move the SL of this same distance in 10th of pips ex 500 = 0.005
//| monStop= delta between the entry and and SL in 10th of pips ex 500 = 0.005
//| modeSecu = if 1 or 2 parse strat string to define safety SL, ex seuilSecu : 100-0!300-100
//| monCoefRessert= if price gothrough coef * monStop monNewTrailing replaces Traling
//| monNewTrailing= replacement trailing in 10th of pips ex 500 = 0.005
//| handle = comment file                                            |
//| f_Debug_Mode = Debug mode                                        |
//| handle_log = order log file                                      |
//| movingTP = move TP in same time than SL ?                        |
//| showTrail = logs trialing infos                                  |
//| returns 1 when ok                                                |
//+------------------------------------------------------------------+
int TrailingStop(const int hticket,double monTrailing,double monStop,/*const int modeSecu=0,const string seuilSecu="",double monCoefRessert=100.0,double monNewTrailing=0.0,*/
                 const int handle=0,const int f_Debug_Mode=0,const int handle_log=0,const bool movingTP=true, const bool showTrail=false)
  {
   int tryUpd=0;

   tryUpd=0;
   while(tryUpd<10)//10 tries
     {
      if(!TrailingStopTicket(hticket,monTrailing,monStop,handle,f_Debug_Mode,movingTP,showTrail,handle_log)<0)
        {
         logMe(handle,9,"OrderTrailing error "+Fun_Error(GetLastError(),true),f_Debug_Mode);
         tryUpd++;
        }
      else
        {
         tryUpd=100;
        }
     }
   if(tryUpd==10)
     {
      logMe(handle,9,"OrderTrailing error 10 TRIES !!!",f_Debug_Mode);
     }

   return(1);
  }

//+------------------------------------------------------------------+
//| Displays the text in the left corner of the graph                |
//+------------------------------------------------------------------+
int DisplayTextLeftCorner(const string name,const string text)
  {
   ObjectDelete(name);
   ObjectCreate(name,OBJ_LABEL,0,0,0,0,0);
   ObjectSet(name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSet(name,OBJPROP_XDISTANCE,10);
   ObjectSet(name,OBJPROP_YDISTANCE,40);
   ObjectSetText(name,text,16,"Tahoma",Yellow);
   return 0;
  }
//+------------------------------------------------------------------+
