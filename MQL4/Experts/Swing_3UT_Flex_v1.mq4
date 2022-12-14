//+---------------------------------------------------------------------+
//|                                               Swing_3UT_Flex.mq4    |
//|                                                      Version 1.0    |
//|                                                             BDUR    |
//| Expert advisor for forex trading                                    |
//| Calculate bias for longest UT, optional                             |
//| Calculate bias for middle UT, optional                              |
//| Seek entry point on third UT, necessary                             |
//| Works with TA indicators in input                                   |
//| According to the MM strat can manage more than one trade            |
//| For the same position                                               |
//| Trailing stop, scale in/out and exit condition in input             |
//| If you find good setup, please, send me a tip                       |
//|                                                                     |
//+---------------------------------------------------------------------+
#property copyright "BDUR"
#property strict // lot of warnings at compilation... 

#include <stdlib.mqh>
#include <FileManagement.mqh>
#include <MoneyManagement.mqh>
#include <EASupport.mqh>
#include <Conversions.mqh>
#include <OrderObject.mqh>
#include <APIIndicators.mqh>

input string I_Begin_Time_H="445"; //Start to activate the EA : 445 = 4:45
input string I_End_Time_H="2145"; // Stop of the EA : 2145 = 21:45
input int I_Mode_Time=1; // activation range 0="all the time" 1="limit Bengin->End"
input string I_Period_Check="M30"; //Period to check for opening trades and trail
input string I_Period_UT1="W1"; //Largest time unit
input string I_ModeOpen_UT1="1x2x3"; //Mode to conbine inputs for UT1
input string I_InputOpen_UT1_1="Point_Pivot_Forex_Sens:99";// Indicator 1 for UT1 trend
input string I_InputOpen_UT1_2="Ichimoku_Alignment:9,26,52,BID-KUMO,0";// Indicator 2 for UT1 trend
input string I_InputOpen_UT1_3="";// Indicator 3 for UT1 trend
input string I_InputOpen_UT1_4="";// Indicator 4 for UT1 trend
input string I_Period_UT2="H4"; //Medium time unit
input string I_ModeOpen_UT2="1x2x3"; //Mode to conbine inputs for UT2
input string I_InputOpen_UT2_1="Ichimoku_Alignment:9,26,52,BID-TENKAN-KIJUN-KUMO,0";// Indicator 1 for UT2 trend
input string I_InputOpen_UT2_2="";// Indicator 2 for UT2 trend
input string I_InputOpen_UT2_3="";// Indicator 3 for UT2 trend
input string I_InputOpen_UT2_4="";// Indicator 4 for UT2 trend
input string I_Period_UT3="M15"; //Shortest time unit
input string I_ModeOpen_UT3="1x2x3"; //Mode to conbine inputs for UT3
input string I_InputOpen_UT3_1="Ichimoku_Alignment:9,26,52,BID-TENKAN-KIJUN-SSA-SSB-CHIKOU,1";// Indicator 1 for UT3 trend
input string I_InputOpen_UT3_2="";// Indicator 2 for UT3 trend
input string I_InputOpen_UT3_3="";// Indicator 3 for UT3 trend
input string I_InputOpen_UT3_4="";// Indicator 4 for UT3 trend
input string I_Period_UT_Close="M15"; //Time unit for close indicators
input string I_InputClose_1="";//  Indicator 1 to close
input string I_InputClose_2="";//  Indicator 2 to close
input string I_InputPyram_1="";//  Indicator 1 to scale in, use UT3
input string I_InputPyram_2="";//  Indicator 2 to scale in, use UT3
input string I_InputPyram_3="";//  Indicator 3 to scale in, use UT3
input int I_Mode_SL=0; //mode to calculate SL 0="lowest for n last bars" 1="ATR" 2="Indicator line"
input string I_Param_SL_1="32"; // First param of SL
input double I_Param_SL_2=3.0; // Second param of SL
input double I_Coef_ATR_SL_Min=1.0; // Coef to calculate minimal SL (ATR 4H)
input int I_SL_Margin=100;// Nb points added to the SL
input double I_Risque_Max_Val=50; // max risk
input double I_Risque_Pct=5; //pct of risk
input double I_Coef_Risque_Pct_Max_Currency=2.0; //pct max per currency
input int I_Max_Concurr_Trade=2; //nb trades per
input int I_Mode_Trailing=0;// trailing mode 0="lowest" 1="ATR" 2="Fixe"
input string I_Param_Trail_1="64";// Param 1 for trailing
input double I_Param_Trail_2=1;// Param 2 for trailing
input int I_PourCent_Close=100; // % trade to close
*/input int  I_PourCent_Pyram=50;//risk % to scale in
input double I_Spread_Limit=600.0; // security max spread
input int I_Debug_Mode=1; // debug mode  0="no debug log" 1="debug logs"
input int I_Prefixe_Magic=1600000;//prefix for magic number
input bool I_MovingTP=true;//if we move TP
input int I_BaseTP=5000; //nb points added to the TP
input string I_Strat_GoalTP="NO"; // Strat for TP based on SL ex : 50-BE*100-40-200-30
input bool I_isBackTest=false;//if it's BackTest
input int I_ModeClose=0;// Close mode : 0 no exit, 1 close only if it's a winning trade, 2 exit all yhe time
input bool I_useStack=false;// if we scale in
input int I_BTScenario=1;// scenario of the file we backtest
input string I_BTFile=""; // File with BT scenarii
input bool I_Bypass_Log=false; // do not print logs in a comment file

datetime now,candl_t,preTime,thisHour,thisHalfHour,thisDay,this4Hour,dateLastClose,dateLastOpen,dateLastAllege,thisPeriod_UT1,thisPeriod_UT2,thisPeriod_UT3,thisPeriod_Check;

double p_nor,monTP=I_BaseTP,monTP1=0.0,monTP2=0.0,monTP3=0.0,TP,SL,monLot=0.0,monLot1=0.0,monLot2=0.0,monLot3=0.0,risqueMax=0.0,risque=0.0,risqueMaxPaire=0.0,
             ATR,f_Coef_ATR_SL,f_Coef_ATR_SL_Min,f_Risque_Max_Val,f_Risque_Pct,f_Param_Trail_2,f_Spread_Limit,risqueEnCours,f_Param_SL_2,f_Coef_Risque_Pct_Max_Currency=2.0;

int ticket,h_log,h_com,h_bt,h_open,tryOrder,nbOrdresEnCours=0,nbOrdresFermes=0,magic=0,heureOuvert=0,
                                            f_Mode_Time=I_Mode_Time,f_Mode_SL=0,f_SL_Margin=0,stratTP1=0,stratSizeTP1=0,stratTP2=0,stratSizeTP2=0,stratBE=0,
                                            f_Mode_Trailing=0,f_Debug_Mode=0,f_Prefixe_Magic=0,f_BTScenario=0,f_BaseTP=500,f_PourCent_Close=75,f_PourCent_Pyram=100,f_ModeClose=0,
                                            intPeriod_UT1=0,intPeriod_UT2=0,intPeriod_UT3=0,intPeriod_UT_Close=0,intPeriod_Check=0,f_Max_Concurr_Trade=1;

bool prems=true,ordreOuvert=false,nouvBar=false,trailInfotoLog=false,f_isBackTest,f_MovingTP,f_useStack,
     newHour,newHalfHour,f_Check_RSI_1d,allege,new4Hour,f_useAllegement=true,
                                                        newPeriod_UT1,newPeriod_UT2,newPeriod_UT3,newPeriod_Check;

string fixeCommentFile="Swing_3UT_Flex_Com",fixeOrderFile="Swing_3UT_Flex_OrderLog",fixeOpenFile="Swing_3UT_Flex_OpenLog",labelRobot="3UT FLEX",openFileName="",fixeSuffixeFile=".csv",
       f_Period_UT1="",f_Period_UT2="",f_Period_UT3="",f_Period_UT_Close="",f_Param_Trail_1="",
       f_Begin_Time_H="",f_End_Time_H="",f_SeuilSecu_Trailing="",f_BTFile="",signal="",f_Lot_Min_Max="",
       trend_ut3_pre="",trend_ut1="no use",trend_ut2="no use",trend_ut3="no use",go_ut3="no use",direction="",
       f_InputOpen_UT1_1="",f_InputOpen_UT1_2="",f_InputOpen_UT1_3="",f_InputOpen_UT1_4="",f_ModeOpen_UT1="",
       f_InputOpen_UT2_1="",f_InputOpen_UT2_2="",f_InputOpen_UT2_3="",f_InputOpen_UT2_4="",f_ModeOpen_UT2="",
       f_InputOpen_UT3_1="",f_InputOpen_UT3_2="",f_InputOpen_UT3_3="",f_InputOpen_UT3_4="",f_ModeOpen_UT3="",
       f_InputClose_1="",f_InputClose_2="",f_InputPyram_1="",f_InputPyram_2="",f_InputPyram_3="",f_Strat_GoalTP="",
       f_Param_SL_1="",name,libTrend="",trend_close="",f_Period_Check=I_Period_Check;

//market param
double minLot = MarketInfo(Symbol(),MODE_MINLOT);
double maxLot = MarketInfo(Symbol(),MODE_MAXLOT);
double stepLot = MarketInfo(Symbol(),MODE_LOTSTEP);
double distMin = MarketInfo(Symbol(),MODE_STOPLEVEL);
double spread=MarketInfo(Symbol(),MODE_SPREAD);

double etatRisque[4],PRO,LOS,RSK,RATIO; // for logs

OrderSelection* myOrdersBook;// init order book
OrderWorker* myOrderWorker;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

   dateLastClose=StringToTime("2015.01.01");// init at 2015 to start

   setFinalInput();   //copy input in variables used by the EA

   /* *************************************************/
   /* FORK for backtests                              */
   /* If I_isBackTest we set parametes from  I_BTFile */
   if(I_isBackTest && IsTesting())
     {
      h_log=openCSVFile(getFileName(fixeOrderFile+"_"+I_BTScenario,fixeSuffixeFile));
      h_com=openCSVFile(getFileName(fixeCommentFile+"_"+I_BTScenario,fixeSuffixeFile),I_Bypass_Log);

      openFileName=getFileName(fixeOpenFile+"_"+I_BTScenario,fixeSuffixeFile);
      h_open=openTXTWriteFile(openFileName);

      writeCommentLog(h_com,0,"BT :  "+I_isBackTest+"file : "+I_BTFile,1);
      h_bt=openTXTReadFile(I_BTFile);
      string maLigne[];
      bool scenar_ok=seekScenario(h_bt,I_BTScenario,maLigne,h_com); //search the scenario line

      if(scenar_ok)
        {
         setScenarioBacktest(maLigne,h_com,f_Debug_Mode); // set vars from file
        }

     }
   else
     {
      h_log=openCSVFile(getFileName(fixeOrderFile,fixeSuffixeFile));
      h_com=openCSVFile(getFileName(fixeCommentFile,fixeSuffixeFile),I_Bypass_Log);

      openFileName=getFileNameGlobal(fixeOpenFile,fixeSuffixeFile);
      h_open=openTXTWriteFile(openFileName);
      FileSeek(h_open,0, SEEK_END);

      logInputs(h_com,f_Debug_Mode);
     }

/* *************************************************/
   /*split the money management strategy              */
   /*f_Strat_GoalTP ex : 50-BE;100-35-200-30$1900     */
   /*50-BE = at 50% of SL we move SL to breakeven     */
   /*100 = TP1 at 100% of SL                          */
   /*35 = % of size to exit at TP1                    */
   /*200 = TP2 at 200% of SL                          */
   /*30 = % of size to exit at TP2 TP2                */
   /*$1900 = Time to close all trades                 */
   string resultSplitPre[],resultSplitBE[],resultSplitStrat[];

   if(StringFind(f_Strat_GoalTP,"BE*",0)>=0)// if there is a BE option
     {
      StringSplit(f_Strat_GoalTP,StringGetCharacter("*",0),resultSplitPre);
      StringSplit(resultSplitPre[0],StringGetCharacter("-",0),resultSplitBE);
      if(resultSplitBE[1]=="BE")
        {
         stratBE=StringToInteger(resultSplitBE[0]);
        }
      else
        {
         logMe(h_com,9," Error splitting BE strat :"+f_Strat_GoalTP,1);
        }

      f_Strat_GoalTP=resultSplitPre[1];// parse strategy
     }

   if(StringSplit(f_Strat_GoalTP,StringGetCharacter("-",0),resultSplitStrat)>=2)
     {
      stratTP1=StringToInteger(resultSplitStrat[0]);
      stratSizeTP1=StringToInteger(resultSplitStrat[1]);
      if(ArraySize(resultSplitStrat)>2)
        {
         stratTP2=StringToInteger(resultSplitStrat[2]);
         stratSizeTP2=StringToInteger(resultSplitStrat[3]);
        }
      logMe(h_com,0,"Strat TP  : Size 1="+stratSizeTP1 + " for "+stratTP1+"% of SL and size 2="+stratSizeTP2+" for "+stratTP2+"% of SL and BE="+stratBE+"% of SL",1);
     }

   /* ***************************************************************/
   /* END FORK for backtests                                      ***/
   /* ***************************************************************/

   intPeriod_UT1=ConvertPeriodStrToInt(f_Period_UT1);
   intPeriod_UT2=ConvertPeriodStrToInt(f_Period_UT2);
   intPeriod_UT3=ConvertPeriodStrToInt(f_Period_UT3);
   intPeriod_UT_Close=ConvertPeriodStrToInt(f_Period_UT_Close);
   intPeriod_Check=ConvertPeriodStrToInt(f_Period_Check);

   preTime=TimeCurrent();

   Verif(minLot,maxLot,distMin,stepLot,0,monLot,0);
   magic=GetMagicNumber(f_Prefixe_Magic,intPeriod_UT3); // set magic number


   writeHeaderOrderLog(h_log,";",f_Debug_Mode); // init order log file
   logMe(h_com,0,"START de "+labelRobot+" Magic : "+magic,f_Debug_Mode);// trace le démarrage
   logMe(h_com,0,"Campaign="+f_BTScenario);
   logMe(h_com,0,"Symbol="+Symbol(),1);
   logMe(h_com,0,"Point size in the quote currency="+MarketInfo(Symbol(),MODE_POINT),f_Debug_Mode);
   logMe(h_com,0,"Minimal tick value in the deposit currency="+MarketInfo(Symbol(),MODE_TICKVALUE),f_Debug_Mode);
   logMe(h_com,0,"Digits after decimal point="+MarketInfo(Symbol(),MODE_DIGITS),f_Debug_Mode);
   logMe(h_com,0,"Stop level in points="+MarketInfo(Symbol(),MODE_STOPLEVEL),f_Debug_Mode);
   logMe(h_com,0,"Defaut Lot size in the base currency="+MarketInfo(Symbol(),MODE_LOTSIZE),f_Debug_Mode);
   logMe(h_com,0,"Tick size in points="+MarketInfo(Symbol(),MODE_TICKSIZE),f_Debug_Mode);
   logMe(h_com,0,"Swap of the buy order="+MarketInfo(Symbol(),MODE_SWAPLONG),f_Debug_Mode);
   logMe(h_com,0,"Swap of the sell order="+MarketInfo(Symbol(),MODE_SWAPSHORT),f_Debug_Mode);
   logMe(h_com,0,"Trade is allowed for the symbol="+MarketInfo(Symbol(),MODE_TRADEALLOWED),f_Debug_Mode);
   logMe(h_com,0,"Minimum permitted amount of a defaut lot="+MarketInfo(Symbol(),MODE_MINLOT),f_Debug_Mode);
   logMe(h_com,0,"Step for changing lots="+MarketInfo(Symbol(),MODE_LOTSTEP),f_Debug_Mode);
   logMe(h_com,0,"Maximum permitted amount of a defaut lot="+MarketInfo(Symbol(),MODE_MAXLOT),f_Debug_Mode);
   logMe(h_com,0,"Swap calculation method="+MarketInfo(Symbol(),MODE_SWAPTYPE),f_Debug_Mode);
   logMe(h_com,0,"Profit calculation mode="+MarketInfo(Symbol(),MODE_PROFITCALCMODE),f_Debug_Mode);
   logMe(h_com,0,"Margin calculation mode="+MarketInfo(Symbol(),MODE_MARGINCALCMODE),f_Debug_Mode);
   logMe(h_com,0,"Initial margin requirements for 1 defaut lot="+MarketInfo(Symbol(),MODE_MARGININIT),f_Debug_Mode);
   logMe(h_com,0,"Margin to maintain open orders calculated for 1 defaut lot="+MarketInfo(Symbol(),MODE_MARGINMAINTENANCE),f_Debug_Mode);
   logMe(h_com,0,"Hedged margin calculated for 1 defaut lot="+MarketInfo(Symbol(),MODE_MARGINHEDGED),f_Debug_Mode);
   logMe(h_com,0,"Free margin required to open 1 defaut lot for buying="+MarketInfo(Symbol(),MODE_MARGINREQUIRED),f_Debug_Mode);
   logMe(h_com,0,"Order freeze level in points="+MarketInfo(Symbol(),MODE_FREEZELEVEL),f_Debug_Mode);

   myOrderWorker=new OrderWorker;
   myOrdersBook=myOrderWorker.GetOpen(magic,Symbol());

   DisplayTextLeftCorner("Info",labelRobot);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   FileClose(h_log);
   FileClose(h_com);
   FileClose(h_bt);
   FileClose(h_open);
   delete myOrdersBook; 
   myOrdersBook=NULL;
   delete myOrderWorker;
   myOrderWorker=NULL;

   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
  {

   now=TimeCurrent();
   spread=MarketInfo(Symbol(),MODE_SPREAD);

   UpdateMyOrderBook();
   nbOrdresEnCours=myOrdersBook.Count();
   nbOrdresFermes=0;
   ordreOuvert=false;

//store date of day for some logs
   if(thisDay!=iTime(Symbol(),PERIOD_D1,0))
     {
      trailInfotoLog=true;
      thisDay=iTime(Symbol(),PERIOD_D1,0);   
      logMe(h_com,0,"Daily Account Balance = "+AccountBalance(),f_Debug_Mode);
     }

//store H4 of day for some logs
   if(this4Hour==iTime(Symbol(),PERIOD_H4,0))
     {
      new4Hour=false;
     }
   else
     {
      new4Hour=true;
      trailInfotoLog=true;
      this4Hour=iTime(Symbol(),PERIOD_H4,0);   
     }

//store hour
   if(thisHour==iTime(Symbol(),PERIOD_H1,0))
     {
      newHour=false;
     }
   else
     {
      newHour=true;
      thisHour=iTime(Symbol(),PERIOD_H1,0);   
      if(myOrdersBook.Count()>0)
        {
         logMe(h_com,0,"Order book :"+myOrdersBook.PrintOrderSelection(),f_Debug_Mode);
        }
     }

   if(thisHalfHour==iTime(Symbol(),PERIOD_M30,0))
     {
      newHalfHour=false;
     }
   else
     {
      newHalfHour=true;
      thisHalfHour=iTime(Symbol(),PERIOD_M30,0);  
     }

   if(thisPeriod_UT1==iTime(Symbol(),intPeriod_UT1,0))
     {
      newPeriod_UT1=false;
     }
   else
     {
      newPeriod_UT1=true;
      thisPeriod_UT1=iTime(Symbol(),intPeriod_UT1,0);   
     }

   if(thisPeriod_UT2==iTime(Symbol(),intPeriod_UT2,0))
     {
      newPeriod_UT2=false;
     }
   else
     {
      newPeriod_UT2=true;
      thisPeriod_UT2=iTime(Symbol(),intPeriod_UT2,0);  
     }

   if(thisPeriod_UT3==iTime(Symbol(),intPeriod_UT3,0))
     {
      newPeriod_UT3=false;
     }
   else
     {
      newPeriod_UT3=true;
      thisPeriod_UT3=iTime(Symbol(),intPeriod_UT3,0);  
     }

   if(thisPeriod_Check==iTime(Symbol(),intPeriod_Check,0))
     {
      newPeriod_Check=false;
     }
   else
     {
      newPeriod_Check=true;
      thisPeriod_Check=iTime(Symbol(),intPeriod_Check,0);  
     }

/****************************
 *** TRADE MANAGEMENT *******
 ****************************/
   if(myOrdersBook.Count()>0 && newPeriod_Check)
     {

      direction="";
      if(myOrdersBook.Get(0).sens>0)
        {
         direction="BUY";
        }
      else
        {
         direction="SELL";
        }
      double openPrice=myOrdersBook.Get(0).openPrice;

      heureOuvert=GoodTime(f_Mode_Time,f_Begin_Time_H,f_End_Time_H);
      if(heureOuvert==-1)
        {
         logMe(h_com,8,"Erreur while GoodTime Mode "+f_Mode_Time+" Symbol "+Symbol()+" Begin "+f_Begin_Time_H+" End "+f_End_Time_H,f_Debug_Mode);
        }

      /****************************
      *** TRAILING STOP     *******
      ****************************/

      for(int i=OrdersTotal(); i>=0; i--) // check SL for each order
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
              {

               int resModify=0;
               TP=OrderTakeProfit();

               //case strat breakeven
               if(stratBE>0)
                 {
                  double openSL=getOpenSL(h_open,myOrdersBook.Get(0).ticket,h_com); // get SL of the position's opening
                  if(openSL==0.0)
                    {
                     openSL= myOrdersBook.Get(0).openStopLoss;
                    }

                  double margeSL=100.0*Point;
                  if(direction=="BUY")
                    {
                     if((Ask-openPrice>(stratBE/100.0)*(openPrice-openSL)) && OrderStopLoss()<openPrice)
                       {
                        logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Ask="+Ask+", open="+openPrice+" margeSL="+margeSL+" openSL="+openSL,f_Debug_Mode);
                        resModify=ModifySL(OrderTicket(),openPrice+margeSL, TP,50.0, h_log,h_com,f_Debug_Mode);
                        if(resModify>0)
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Go BE because Ask="+Ask+" and open="+openPrice,f_Debug_Mode);
                          }
                        else
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Error update BE",f_Debug_Mode);
                          }
                       }
                    }
                  else
                    {
                     if((openPrice-Bid>(stratBE/100.0)*(openSL-openPrice)) && OrderStopLoss()>openPrice)
                       {
                        resModify=ModifySL(OrderTicket(),openPrice-margeSL, TP,50.0,h_log,h_com,f_Debug_Mode);
                        if(resModify>0)
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Go BE because Bid="+Bid+" and open="+openPrice,f_Debug_Mode);
                          }
                        else
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Error update BE",f_Debug_Mode);
                          }

                       }

                    }
                 }

               if(f_Mode_Trailing==1) //with ATR
                 {
                  ATR=ATRinPoints(Symbol(),StringToInteger(f_Param_Trail_1),intPeriod_UT3);
                  if(ATR*f_Param_SL_2<f_Coef_ATR_SL_Min)
                    {
                     ATR=f_Coef_ATR_SL_Min/f_Param_SL_2;
                    }
                  TrailingStop(OrderTicket(),ATR*f_Param_Trail_2,(ATR*f_Param_Trail_2),h_com,f_Debug_Mode,h_log,f_MovingTP,trailInfotoLog); 
                  trailInfotoLog=false;
                 }
               else   
                 {
                  if(f_Mode_Trailing==2)//fix
                    {
                     TrailingStop(OrderTicket(),StringToInteger(f_Param_Trail_1),f_Param_Trail_2,h_com,f_Debug_Mode,h_log,f_MovingTP,trailInfotoLog); 
                     trailInfotoLog=false;
                    }
                  else
                    {
                     if(f_Mode_Trailing==0)/ lowest / highest
                       {
                        SL=getDeltaSL(direction,intPeriod_UT3,f_Mode_Trailing,f_Param_Trail_1,f_Param_Trail_2,h_com);//get size SL

                        //At least 2 ATR(12)
                        if(SL<f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod_UT3,12,1))
                          {
                           SL=f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod_UT3,12,1);
                           if(newPeriod_UT3)
                             {
                              logMe(h_com,0,"TRAIL MODE 0 size SL modified "+SL,f_Debug_Mode);
                             }
                          }

                        SL=SL+(f_SL_Margin*Point)+(spread*Point); // add 10 points for spread and safety
                        if(direction=="BUY")
                          {
                           if(f_MovingTP)
                             {
                              TP=TP+(I_BaseTP*Point);
                              if(TP>500.0)
                                {
                                 TP=500.0;
                                }
                             }
                           resModify=ModifySL(OrderTicket(),Bid-SL, TP,50.0, h_log,h_com,f_Debug_Mode);
                          }
                        else
                          {
                           if(f_MovingTP)
                             {
                              TP=TP-(I_BaseTP*Point);
                              if(TP<0.0)
                                {
                                 TP=0.0;
                                }
                             }
                           resModify=ModifySL(OrderTicket(),Ask+SL, TP,50.0,h_log,h_com,f_Debug_Mode);
                          }
                       }
                    }
                 }

               if(resModify==1)
                 {
                  logMe(h_com,1,"TrailingStopTicket : order updated.",f_Debug_Mode);
                 }
               if(resModify==-1)
                 {
                  logMe(h_com,9,"TrailingStopTicket : error trying updating the order.",f_Debug_Mode);
                 }
               UpdateMyOrderBook();
              }
           }
        }//end for

      /***********************/
      /*** CLOSE      ********/
      /***********************/
      if(f_ModeClose>0 && ((now-dateLastClose)/60)>intPeriod_UT3*12 && (now-dateLastOpen/60)>intPeriod_UT3*2 && heureOuvert==1)
        {// Check if we use close, and condition since last close order and last open order to let the asset breath

         string  msg="", msgLog="",trend_ut3_close="no trend";
         msg="";
         trend_close="no trend"; // reset
         msgLog=" direction : "+direction;
         bool exit=false;

         if(f_InputClose_1!="")// check first condition
           {
            StringReplace(f_InputClose_1,"#ORDER#",direction);
            double indic_close_1=getIndicatorFromParam(Symbol(), intPeriod_UT_Close,f_InputClose_1,h_com);
            trend_close="no trend";

            if(indic_close_1>0)
              {
               trend_close="up";   
              }
            if(indic_close_1<0)
              {
               trend_close="down";
              }
            if(indic_close_1==6666.0)
              {
               trend_close="out";
              }
            msgLog+="Indic 1 : "+trend_close+" "+indic_close_1+" ";

            if(((direction=="BUY" && (trend_close=="down" || trend_close=="out") && (Ask>openPrice || f_ModeClose==2))
                || (direction=="SELL" && (trend_close=="up" || trend_close=="out") && (Bid<openPrice || f_ModeClose==2))))
              {// if trend goes against the trade we close
               exit=true;
               msg="trend_close indic 1 "+trend_close +" indic_close_1 "+indic_close_1;
              }
           }

         if(f_InputClose_2!="")// check second condition
           {
            StringReplace(f_InputClose_2,"#ORDER#",direction);
            double indic_close_2=getIndicatorFromParam(Symbol(), intPeriod_UT_Close,f_InputClose_2,h_com);

            if(indic_close_2>0 && trend_close=="down")
              {
               trend_close="neutral";   
              }
            if(indic_close_2<0 && trend_close=="up")
              {
               trend_close="neutral";
              }
            msgLog+="Indic 2 : "+trend_close+" "+indic_close_2+" ";

            if(((direction=="BUY" && (trend_close=="down" || trend_close=="out"))
                || (direction=="SELL" && (trend_close=="up" || trend_close=="out"))))
              {
               exit=true;
               msg="trend_close indic 2"+trend_close +" indic_close_2 "+indic_close_2;
              }
            else
              {
               exit=false;
              }
           }

         if(newPeriod_UT3)
           {
            logMe(h_com,1,"CLOSE MODE "+f_ModeClose+"  : "+msgLog,f_Debug_Mode);
           }

         if(exit)
           {
            logMe(h_com,1,"CLOSE "+f_PourCent_Close+"% detail : "+msg,f_Debug_Mode);


            int nbOrdresFermes=DecreasePosition(myOrdersBook,NormalizeDouble(myOrdersBook.TotalPosition()*(f_PourCent_Close/100.0),2), h_log,h_com,f_Debug_Mode);
            if(nbOrdresFermes>0)
              {
               logMe(h_com,1,"CLOSE "+nbOrdresFermes+" closed orders.",f_Debug_Mode);
               UpdateMyOrderBook();
               dateLastClose=now;
               dateLastAllege=now;
              }

           }
        }// end close

   /***********************/
   /*** SCALE IN   ********/
   /***********************/
      if(myOrdersBook.Count()>0 && myOrdersBook.Count()<10 && f_useStack  && ((now-dateLastOpen)/60)>intPeriod_UT3) 
        {
         ordreOuvert=true;

         //check actual risk of the order book
         risqueEnCours=myOrdersBook.getRiskToral();
         if(risqueEnCours<f_Risque_Pct)
           {

            spread=MarketInfo(Symbol(),MODE_SPREAD); 

            //-------------------------send Orders
            if(heureOuvert==1 && ((direction=="BUY" && Bid>openPrice)  || (direction=="SELL" && Ask<openPrice)))
              {

               bool renforcer=false;
               double indic_pyram_1=-9999,indic_pyram_2=-9999,indic_pyram_3=-9999;

               if(f_InputPyram_1!="")
                 {
                  StringReplace(f_InputPyram_1,"#ORDER#",direction);
                  indic_pyram_1=getIndicatorFromParam(Symbol(), intPeriod_UT3,f_InputPyram_1,h_com);
                  if(f_InputPyram_2!="")
                    {
                     StringReplace(f_InputPyram_2,"#ORDER#",direction);
                     indic_pyram_2=getIndicatorFromParam(Symbol(), intPeriod_UT3,f_InputPyram_2,h_com);

                     if(f_InputPyram_3!="")
                       {
                        StringReplace(f_InputPyram_3,"#ORDER#",direction);
                        indic_pyram_3=getIndicatorFromParam(Symbol(), intPeriod_UT3,f_InputPyram_3,h_com);
                       }
                    }
                 }

               //

               if(direction=="BUY" && (indic_pyram_1>0 || indic_pyram_1==-9999)
                  && (indic_pyram_2>0 || indic_pyram_2==-9999) && (indic_pyram_3>0 || indic_pyram_3==-9999))
                 {
                  renforcer=true;
                 }
               if(direction=="SELL" && (indic_pyram_1<0 || indic_pyram_1==-9999)
                  && (indic_pyram_2<0 || indic_pyram_2==-9999)  && (indic_pyram_3<0 || indic_pyram_3==-9999))
                 {
                  renforcer=true;
                 }

               logMe(h_com,0,"Scale in indic_pyram_1:"+indic_pyram_1+" indic_pyram_2:"+indic_pyram_2+" indic_pyram_3:"+indic_pyram_3,f_Debug_Mode);

               if(renforcer)

                 {
                  SL=MathAbs(Bid-myOrdersBook.Get(0).stopLoss);
                  logMe(h_com,0,"SL myOrdersBook : "+myOrdersBook.Get(0).stopLoss + " -- calculate size SL : "+DoubleToStr(SL,5),f_Debug_Mode);

                  /* calculate position size */
                  risqueMax=CalculateRisk(f_Risque_Max_Val);// returns risk max in %
                  risqueMax=risqueMax*(f_PourCent_Pyram/100.0); // risk max for pyramiding
                  risque= risqueMax-risqueEnCours;//calculates free risk
                  if(risque>0.0)
                    {
                     monLot=CalculateVol(signal,risque,SL,h_com); // lot size

                    }
                  else
                    {
                     monLot=0.0;
                    }

                  if(monLot==0.0)
                    {
                     logMe(h_com,0,"Scale in canceled cause of risk "+DoubleToStr(risque,2)+"% and SL at "+DoubleToStr(SL,5),f_Debug_Mode);
                    }

                  monLot=NormalizeDouble(monLot,2);
                  logMe(h_com,0,"Risk ("+DoubleToStr(risque,2)+") risk max("+DoubleToStr(risqueMax,2)+") SL : "+DoubleToStr(SL,5)+" monLot : "+DoubleToStr(monLot,2),f_Debug_Mode);

                  if(SL>0.0 && monLot>0.0)
                    {
                     dateLastOpen=now;

                     monTP=f_BaseTP*Point ;
                     if(monTP<20*SL) // if TP too close
                       {
                        monTP=20.0*SL;
                       }

                     if(stratTP1>0)
                       {
                        monLot1=0.0;
                        monLot2=0.0;
                        monLot3=0.0;
                        monTP1=monTP;
                        monTP2=monTP;
                        monTP3=monTP;
                        monLot1=SplitOrderStrat(monLot,stratSizeTP1,h_com,f_Debug_Mode);

                        if(stratTP2>0 && NormalizeDouble(monLot-monLot1,2)>0.01)
                          {
                           monLot2=SplitOrderStrat(monLot,stratSizeTP2,h_com,f_Debug_Mode);

                           if(NormalizeDouble(monLot-monLot1-monLot2,2)>=0.01)
                             {
                              monLot3=monLot-monLot1-monLot2;
                              if(monLot3>monLot1 || monLot3>monLot2)
                                {
                                 monLot3=monLot2;
                                }
                              monLot3=NormalizeDouble(monLot3,2);
                             }
                          }
                        else
                          {
                           monLot2=monLot-monLot1;
                           monLot2=NormalizeDouble(monLot2,2);
                          }
                        logMe(h_com,0," monLot : "+monLot+" monLot1 : "+monLot1+ " monLot2 : "+monLot2+" monLot3 : "+monLot3,f_Debug_Mode);
                        if(monLot1>0.0)
                          {
                           // Send orders accordint to strategy
                           if(stratTP1>0)
                             {
                              monTP1=SL*(stratTP1/100.0);
                             }
                           ticket=sendOrder(magic,direction,labelRobot+" Scale in Trade 1",SL,monLot1,monTP1,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                           if(ticket<0)
                             {
                              logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                             }

                           if(monLot2>0.0)
                             {
                              if(stratTP2>0 && monLot3>0.0)
                                {
                                 monTP2=SL*(stratTP2/100.0);
                                }
                              ticket=sendOrder(magic,direction,labelRobot+" Scale in Trade 2",SL,monLot2,monTP2,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                              if(ticket<0)
                                {
                                 logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                                }

                              if(monLot3>0.0)
                                {
                                 ticket=sendOrder(magic,direction,labelRobot+" Scale in Trade 3",SL,monLot3,monTP3,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                                 if(ticket<0)
                                   {
                                    logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                                   }
                                }
                             }
                          }

                       }
                     else  // no strat
                       {

                        ticket=sendOrder(magic,direction,labelRobot+" Scale in ",SL,monLot,monTP,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                        if(ticket<0)
                          {
                           logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                          }
                       }
                     UpdateMyOrderBook();

                    }
                 }
              }
           }
        }
     }

   /***********************/
   /***** OPENING *********/
   /***********************/

   heureOuvert=GoodTime(f_Mode_Time,f_Begin_Time_H,f_End_Time_H);//is it time to trade ?
   if(heureOuvert==-1)
     {
      writeCommentLog(h_com,8,"Erreur lors de GoodTime Mode "+f_Mode_Time+" Symbol "+Symbol()+" Begin "+f_Begin_Time_H+" End "+f_End_Time_H,f_Debug_Mode);
     }

   if(newPeriod_Check && heureOuvert==1 && myOrdersBook.Count()==0)//if it's a new period during the good time and without opened order, go
     {
      trend_ut3_pre=trend_ut1+"-"+trend_ut2+"-"+trend_ut3;//reset variables
      signal="no signal";
      trend_ut1="no trend";
      trend_ut2="no use";
      trend_ut3="no use";
      go_ut3="no use";

      trend_ut1=getTrend(f_ModeOpen_UT1,intPeriod_UT1,f_InputOpen_UT1_1,f_InputOpen_UT1_2,f_InputOpen_UT1_3,f_InputOpen_UT1_4,h_com);

      trend_ut2=getTrend(f_ModeOpen_UT2,intPeriod_UT2,f_InputOpen_UT2_1,f_InputOpen_UT2_2,f_InputOpen_UT2_3,f_InputOpen_UT2_4,h_com);

      trend_ut3=getTrend(f_ModeOpen_UT3,intPeriod_UT3,f_InputOpen_UT3_1,f_InputOpen_UT3_2,f_InputOpen_UT3_3,f_InputOpen_UT3_4,h_com);

      logMe(h_com,1,"Trends : trend_ut1="+trend_ut1+" trend_ut2="+trend_ut2+" trend_ut3="+trend_ut3,f_Debug_Mode);

      if(trend_ut1=="ERROR" || trend_ut2=="ERROR" || trend_ut3=="ERROR")
        {
         logMe(h_com,9,"ERROR DURING TREND CALCULATION : UT1="+trend_ut1+" UT2="+trend_ut2+" UT3="+trend_ut3,f_Debug_Mode);
        }
      else
        {
         if((trend_ut1=="up" || trend_ut1=="no use")
            && (trend_ut2=="up"  || trend_ut2=="no use")
            && (trend_ut3=="up"))
           {
            signal="BUY";
           }

         if((trend_ut1=="down" || trend_ut1=="no use")
            && (trend_ut2=="down"   || trend_ut2=="no use")
            && (trend_ut3=="down"))
           {
            signal="SELL";
           }

         if(trend_ut3_pre!=trend_ut1+"-"+trend_ut2+"-"+trend_ut3)
           {
            libTrend="";
            if(f_InputOpen_UT1_1!="")
              {
               libTrend+="Trend UT1="+trend_ut1 ;
              }
            if(f_InputOpen_UT2_1!="")
              {
               libTrend+="--Trend UT2="+trend_ut2;
              }
            if(f_InputOpen_UT3_1!="")
              {
               libTrend+="--Trend UT3="+trend_ut3;
              }

            logMe(h_com,1,libTrend,f_Debug_Mode);
            DisplayTextLeftCorner("Info",labelRobot+" "+libTrend);
           }
        }

      //-------------------------send Orders
      if(heureOuvert==1 && (signal=="BUY" || signal=="SELL"))
        {
         writeCommentLog(h_com,0,"SIGNAL : "+signal,f_Debug_Mode);

         SL=getDeltaSL(signal,intPeriod_UT3,f_Mode_SL,f_Param_SL_1,f_Param_SL_2,h_com);//calcul of SL
         //At least n ATR(12)
         double SL_min=f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod_UT3,12,1);
         if(SL<SL_min)
           {
            // SL minimal
            logMe(h_com,0,"SL "+SL+" <"+f_Coef_ATR_SL_Min+"*iATR(12)*Point "+SL_min,f_Debug_Mode);
            SL=SL_min;

           }

         SL=SL+(f_SL_Margin*Point)+(spread*Point); // add 10 pips for safety

         risqueMaxPaire=checkOrderCurrency(Symbol(),f_Risque_Pct*f_Coef_Risque_Pct_Max_Currency, h_com,f_Max_Concurr_Trade); //max risk if there are orders with the same currency but othe pair

         risqueMax=CalculateRisk(f_Risque_Max_Val); // !! returns 0.05 instead of  5.0%
         if(risqueMax>risqueMaxPaire)
           {
            risqueMax=risqueMaxPaire;
           }
         risque=f_Risque_Pct;
         logMe(h_com,0,"f_Risque_Pct : "+f_Risque_Pct+ " risque : "+risque+" f_Risque_Max_Val : "+f_Risque_Max_Val+" risqueMax : "+ risqueMax+" risqueMaxPaire: "+risqueMaxPaire,f_Debug_Mode);
         if(risque>risqueMax)
           {
            risque=risqueMax;
           }

         monLot=CalculateVol(signal,risque,SL,h_com); // calculate size of the position

         logMe(h_com,0,"SL (min "+SL_min+") risk max("+risqueMax+") SL : "+SL+" monLot : "+monLot,f_Debug_Mode);

         monTP=f_BaseTP*Point ;
         if(monTP<20*SL) // basic TP at least at 20 SL
           {
            monTP=20.0*SL;
           }

         if(stratTP1>0)
           {
            monLot1=0.0;
            monLot2=0.0;
            monLot3=0.0;
            monTP1=monTP;
            monTP2=monTP;
            monTP3=monTP;
            //split position
            monLot1=SplitOrderStrat(monLot,stratSizeTP1,h_com,f_Debug_Mode);
            if(stratTP2>0 && NormalizeDouble(monLot-monLot1,2)>0.01)
              {
               monLot2=SplitOrderStrat(monLot,stratSizeTP2,h_com,f_Debug_Mode);
               if(NormalizeDouble(monLot-monLot1-monLot2,2)>=0.01)
                 {
                  monLot3=monLot-monLot1-monLot2;
                  if(monLot3>monLot1 || monLot3>monLot2)
                    {
                     monLot3=monLot2;
                    }
                  monLot3=NormalizeDouble(monLot3,2);
                 }
              }
            else
              {
               monLot2=monLot-monLot1;
               monLot2=NormalizeDouble(monLot2,2);
              }
            logMe(h_com,0," monLot : "+monLot+" monLot1 : "+monLot1+ " monLot2 : "+monLot2+" monLot3 : "+monLot3,f_Debug_Mode);

            if(monLot1>0.0)
              {
               // first order
               if(stratTP1>0)
                 {
                  monTP1=SL*(stratTP1/100.0);
                 }
               ticket=sendOrder(magic,signal,labelRobot+" Open Trade 1",SL,monLot1,monTP1,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
               if(ticket<0)
                 {
                  logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                 }

               if(monLot2>0.0)
                 {
                  // second order 
                  if(stratTP2>0 && monLot3>0.0)
                    {
                     monTP2=SL*(stratTP2/100.0);
                    }
                  ticket=sendOrder(magic,signal,labelRobot+" Open Trade 2",SL,monLot2,monTP2,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                  if(ticket<0)
                    {
                     logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                    }

                  if(monLot3>0.0)
                    {
                     // third order 
                     ticket=sendOrder(magic,signal,labelRobot+" Open Trade 3",SL,monLot3,monTP3,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
                     if(ticket<0)
                       {
                        logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
                       }
                    }
                 }
              }
            else
              {
               logMe(h_com,9,"MonLot1 = 0 KO !!, check step lot",f_Debug_Mode);
              }

           }
         else  // pas de strat
           {
            ticket=sendOrder(magic,signal,"3UT FLEX Open",SL,monLot,monTP,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
            if(ticket<0)
              {
               logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
              }
           }// fin si strat
         UpdateMyOrderBook();
         logMe(h_com,0,"Etat du carnet:"+myOrdersBook.PrintOrderSelection(),f_Debug_Mode);// show order book
         dateLastOpen=now;//used for scale in/out and close
        }//if(heureOuvert)
     }//if(nouvBar)
   Sleep(1000);
  }
//+------------------------------------------------------------------+
//+--------------------END ALGO PRINCIPAL----------------------------+
//+------------------------------------------------------------------+

//ResetOrderBook : drop/create of an order book
// return 0
int ResetOrderBook()
  {
   delete(myOrdersBook);
   myOrdersBook=NULL;
   myOrdersBook=myOrderWorker.GetOpen(magic,Symbol()); 
   return 0;
  }

//UpdateOrderBook : Updates the order book in memory
//return 0
int UpdateMyOrderBook()
  {
   if(CheckPointer(myOrdersBook)!=POINTER_INVALID)
     {
      if(myOrdersBook.Count()>0)
        {
         myOrdersBook=myOrderWorker.UpdateOrderBook(myOrdersBook,magic,Symbol());//get a new order book updated
        }
      else
        {
         ResetOrderBook();
        }
     }
   else
     {
      ResetOrderBook();
     }
   return 0;
  }

//set final variables f_Var by inputs
int setFinalInput()
  {
   f_Begin_Time_H=I_Begin_Time_H;
   f_End_Time_H=I_End_Time_H;
   f_Mode_Time=I_Mode_Time;
   f_Period_UT1=I_Period_UT1;
   f_ModeOpen_UT1=I_ModeOpen_UT1;
   f_InputOpen_UT1_1=I_InputOpen_UT1_1;
   f_InputOpen_UT1_2=I_InputOpen_UT1_2;
   f_InputOpen_UT1_3=I_InputOpen_UT1_3;
   f_InputOpen_UT1_4=I_InputOpen_UT1_4;
   f_Period_UT2=I_Period_UT2;
   f_ModeOpen_UT2=I_ModeOpen_UT2;
   f_InputOpen_UT2_1=I_InputOpen_UT2_1;
   f_InputOpen_UT2_2=I_InputOpen_UT2_2;
   f_InputOpen_UT2_3=I_InputOpen_UT2_3;
   f_InputOpen_UT2_4=I_InputOpen_UT2_4;
   f_Period_UT3=I_Period_UT3;
   f_ModeOpen_UT3=I_ModeOpen_UT3;
   f_InputOpen_UT3_1=I_InputOpen_UT3_1;
   f_InputOpen_UT3_2=I_InputOpen_UT3_2;
   f_InputOpen_UT3_3=I_InputOpen_UT3_3;
   f_InputOpen_UT3_4=I_InputOpen_UT3_4;
   f_Period_UT_Close=I_Period_UT_Close;
   f_InputClose_1=I_InputClose_1;
   f_InputClose_2=I_InputClose_2;
   f_InputPyram_1=I_InputPyram_1;
   f_InputPyram_2=I_InputPyram_2;
   f_InputPyram_3=I_InputPyram_3;
   f_Mode_SL=I_Mode_SL;
   f_Param_SL_1=I_Param_SL_1;
   f_Param_SL_2=I_Param_SL_2;
   f_Coef_ATR_SL_Min=I_Coef_ATR_SL_Min;
   f_SL_Margin=I_SL_Margin;
   f_Risque_Max_Val=I_Risque_Max_Val;
   f_Risque_Pct=I_Risque_Pct;
   f_Coef_Risque_Pct_Max_Currency=I_Coef_Risque_Pct_Max_Currency;
   f_Max_Concurr_Trade=I_Max_Concurr_Trade;
   f_Mode_Trailing=   I_Mode_Trailing;
   f_Param_Trail_1=   I_Param_Trail_1;
   f_Param_Trail_2=   I_Param_Trail_2;
   f_PourCent_Close=I_PourCent_Close;
   f_PourCent_Pyram=I_PourCent_Pyram;
   f_Spread_Limit=I_Spread_Limit;
   f_Debug_Mode=I_Debug_Mode;
   f_Prefixe_Magic=I_Prefixe_Magic;
   f_isBackTest=I_isBackTest;
   f_BTScenario=I_BTScenario;
   f_BTFile=I_BTFile;
   f_MovingTP=I_MovingTP;
   f_BaseTP=I_BaseTP;
   f_Strat_GoalTP=I_Strat_GoalTP;
   f_ModeClose=I_ModeClose;
   f_useStack=I_useStack;

   return 1;
  }
  
//set variabels f_ with inputs from scenarii file
//monTab = an array with the data of the scenario
int setScenarioBacktest(const string &monTab[],const int handle=0,const int debugMode=0)
  {
   if(ArraySize(monTab)>0)
     {
      logMe(handle,6,"Load scenario "+monTab[0]+" - "+monTab[1],debugMode);
      f_BTScenario=monTab[0];
      f_Begin_Time_H=monTab[2];
      logMe(handle,1,"f_Begin_Time_H : "+f_Begin_Time_H,debugMode);
      f_End_Time_H=monTab[3];
      logMe(handle,1,"f_End_Time_H : "+f_End_Time_H,debugMode);

      f_Period_UT1=monTab[4];
      logMe(handle,1,"f_Period_UT1 : "+f_Period_UT1,debugMode);
      f_ModeOpen_UT1=monTab[5];
      logMe(handle,1,"f_ModeOpen_UT1 : "+f_ModeOpen_UT1,debugMode);
      f_InputOpen_UT1_1=monTab[6];
      logMe(handle,1,"f_InputOpen_UT1_1 : "+f_InputOpen_UT1_1,debugMode);
      f_InputOpen_UT1_2=monTab[7];
      logMe(handle,1,"f_InputOpen_UT1_2 : "+f_InputOpen_UT1_2,debugMode);
      f_InputOpen_UT1_3=monTab[8];
      logMe(handle,1,"f_InputOpen_UT1_3 : "+f_InputOpen_UT1_3,debugMode);
      f_InputOpen_UT1_4=monTab[9];
      logMe(handle,1,"f_InputOpen_UT1_4 : "+f_InputOpen_UT1_4,debugMode);
      f_Period_UT2=monTab[10];
      logMe(handle,1,"f_Period_UT2 : "+f_Period_UT2,debugMode);
      f_ModeOpen_UT2=monTab[11];
      logMe(handle,1,"f_ModeOpen_UT2 : "+f_ModeOpen_UT2,debugMode);
      f_InputOpen_UT2_1=monTab[12];
      logMe(handle,1,"f_InputOpen_UT2_1 : "+f_InputOpen_UT2_1,debugMode);
      f_InputOpen_UT2_2=monTab[13];
      logMe(handle,1,"f_InputOpen_UT2_2 : "+f_InputOpen_UT2_2,debugMode);
      f_InputOpen_UT2_3=monTab[14];
      logMe(handle,1,"f_InputOpen_UT2_3 : "+f_InputOpen_UT2_3,debugMode);
      f_InputOpen_UT2_4=monTab[15];
      logMe(handle,1,"f_InputOpen_UT2_4 : "+f_InputOpen_UT2_4,debugMode);
      f_Period_UT3=monTab[16];
      logMe(handle,1,"f_Period_UT3 : "+f_Period_UT3,debugMode);
      f_ModeOpen_UT3=monTab[17];
      logMe(handle,1,"f_ModeOpen_UT3 : "+f_ModeOpen_UT3,debugMode);
      f_InputOpen_UT3_1=monTab[18];
      logMe(handle,1,"f_InputOpen_UT3_1 : "+f_InputOpen_UT3_1,debugMode);
      f_InputOpen_UT3_2=monTab[19];
      logMe(handle,1,"f_InputOpen_UT3_2 : "+f_InputOpen_UT3_2,debugMode);
      f_InputOpen_UT3_3=monTab[20];
      logMe(handle,1,"f_InputOpen_UT3_3 : "+f_InputOpen_UT3_3,debugMode);
      f_InputOpen_UT3_4=monTab[21];
      logMe(handle,1,"f_InputOpen_UT3_4 : "+f_InputOpen_UT3_4,debugMode);
      f_Period_UT_Close=monTab[22];
      logMe(handle,1,"f_Period_UT_Close : "+f_Period_UT_Close,debugMode);
      f_InputClose_1=monTab[23];
      logMe(handle,1,"f_InputClose_1 : "+f_InputClose_1,debugMode);
      f_InputClose_2=monTab[24];
      logMe(handle,1,"f_InputClose_2 : "+f_InputClose_2,debugMode);
      f_InputPyram_1=monTab[25];
      logMe(handle,1,"f_InputPyram_1 : "+f_InputPyram_1,debugMode);
      f_InputPyram_2=monTab[26];
      logMe(handle,1,"f_InputPyram_2 : "+f_InputPyram_2,debugMode);
      f_InputPyram_3=monTab[27];
      logMe(handle,1,"f_InputPyram_3 : "+f_InputPyram_3,debugMode);

      if(IsInteger(monTab[28]))
        {
         f_Mode_SL=StringToInteger(monTab[28]);
         logMe(handle,1,"f_Mode_SL : "+f_Mode_SL,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_SL : "+monTab[28],debugMode);
        }
      f_Param_SL_1=monTab[29];
      logMe(handle,1,"f_Param_SL_1 : "+f_Param_SL_1,debugMode);
      if(IsNumber(monTab[30]))
        {
         f_Param_SL_2=StringToDouble(monTab[30]);
         logMe(handle,1,"f_Param_SL_2 : "+f_Param_SL_2,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Param_SL_2 : "+monTab[30],debugMode);
        }
      if(IsNumber(monTab[31]))
        {
         f_Coef_ATR_SL_Min=StringToDouble(monTab[31]);
         logMe(handle,1,"f_Coef_ATR_SL_Min : "+f_Coef_ATR_SL_Min,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Coef_ATR_SL_Min : "+monTab[31],debugMode);
        }
      if(IsInteger(monTab[32]))
        {
         f_SL_Margin=StringToInteger(monTab[32]);
         logMe(handle,1,"f_SL_Margin : "+f_SL_Margin,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_SL_Margin : "+monTab[32],debugMode);
        }
      if(IsNumber(monTab[33]))
        {
         f_Risque_Max_Val=StringToDouble(monTab[33]);
         logMe(handle,1,"f_Risque_Max_Val : "+f_Risque_Max_Val,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Risque_Max_Val : "+monTab[33],debugMode);
        }
      if(IsNumber(monTab[34]))
        {
         f_Risque_Pct=StringToDouble(monTab[34]);
         logMe(handle,1,"f_Risque_Pct : "+f_Risque_Pct,debugMode);
        }
      else
        {
         logMe(handle,9,"EError loading f_Risque_Pct : "+monTab[34],debugMode);
        }
      if(IsInteger(monTab[35]))
        {
         f_Mode_Trailing=StringToInteger(monTab[35]);
         logMe(handle,1,"f_Mode_Trailing : "+f_Mode_Trailing,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_Trailing : "+monTab[35],debugMode);
        }
      f_Param_Trail_1=StringToDouble(monTab[36]);
      logMe(handle,1,"f_Param_Trail_1 : "+f_Param_Trail_1,debugMode);
      if(IsNumber(monTab[31]))
        {
         f_Param_Trail_2=StringToDouble(monTab[37]);
         logMe(handle,1,"f_Param_Trail_2 : "+f_Param_Trail_2,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Param_Trail_2 : "+monTab[37],debugMode);
        }
      if(IsInteger(monTab[38]))
        {
         f_PourCent_Close=StringToInteger(monTab[38]);
         logMe(handle,1,"f_PourCent_Close : "+f_PourCent_Close,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_PourCent_Close : "+monTab[38],debugMode);
        }
      if(IsInteger(monTab[39]))
        {
         f_PourCent_Pyram=StringToInteger(monTab[39]);
         logMe(handle,1,"f_PourCent_Pyram : "+f_PourCent_Pyram,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_PourCent_Pyram : "+monTab[39],debugMode);
        }
      if(IsBool(monTab[40]))
        {
         f_MovingTP=StringToBool(monTab[40]);
         logMe(handle,1,"f_MovingTP : "+f_MovingTP,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_MovingTP : "+monTab[40],debugMode);
        }
      f_Strat_GoalTP=monTab[41];
      logMe(handle,1,"f_Strat_GoalTP : "+f_Strat_GoalTP,debugMode);
      if(IsInteger(monTab[42]))
        {
         f_ModeClose=StringToInteger(monTab[42]);
         logMe(handle,1,"f_ModeClose : "+f_ModeClose,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_ModeClose : "+monTab[42],debugMode);
        }
      if(IsBool(monTab[43]))
        {
         f_useStack=StringToBool(monTab[43]);
         logMe(handle,1,"f_useStack : "+f_useStack,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_useStack : "+monTab[43],debugMode);
        }

      return 1;
     }
   else
     {
      return 0;
     }

  }


//log inputs
int logInputs(const int handle=0,const int debugMode=0)
  {
   logMe(handle,1,"f_Mode_Time : "+f_Mode_Time,debugMode);
   logMe(handle,1,"f_Begin_Time_H : "+f_Begin_Time_H,debugMode);
   logMe(handle,1,"f_End_Time_H : "+f_End_Time_H,debugMode);
   logMe(handle,1,"f_Period_UT1 : "+f_Period_UT1,debugMode);
   logMe(handle,1,"f_ModeOpen_UT1 : "+f_ModeOpen_UT1,debugMode);
   logMe(handle,1,"f_InputOpen_UT1_1 : "+f_InputOpen_UT1_1,debugMode);
   logMe(handle,1,"f_InputOpen_UT1_2 : "+f_InputOpen_UT1_2,debugMode);
   logMe(handle,1,"f_InputOpen_UT1_3 : "+f_InputOpen_UT1_3,debugMode);
   logMe(handle,1,"f_InputOpen_UT1_4 : "+f_InputOpen_UT1_4,debugMode);
   logMe(handle,1,"f_Period_UT2 : "+f_Period_UT2,debugMode);
   logMe(handle,1,"f_ModeOpen_UT2 : "+f_ModeOpen_UT2,debugMode);
   logMe(handle,1,"f_InputOpen_UT2_1 : "+f_InputOpen_UT2_1,debugMode);
   logMe(handle,1,"f_InputOpen_UT2_2 : "+f_InputOpen_UT2_2,debugMode);
   logMe(handle,1,"f_InputOpen_UT2_3 : "+f_InputOpen_UT2_3,debugMode);
   logMe(handle,1,"f_InputOpen_UT2_4 : "+f_InputOpen_UT2_4,debugMode);
   logMe(handle,1,"f_Period_UT3 : "+f_Period_UT3,debugMode);
   logMe(handle,1,"f_ModeOpen_UT3 : "+f_ModeOpen_UT3,debugMode);
   logMe(handle,1,"f_InputOpen_UT3_1 : "+f_InputOpen_UT3_1,debugMode);
   logMe(handle,1,"f_InputOpen_UT3_2 : "+f_InputOpen_UT3_2,debugMode);
   logMe(handle,1,"f_InputOpen_UT3_3 : "+f_InputOpen_UT3_3,debugMode);
   logMe(handle,1,"f_InputOpen_UT3_4 : "+f_InputOpen_UT3_4,debugMode);
   logMe(handle,1,"f_Period_UT_Close : "+f_Period_UT_Close,debugMode);
   logMe(handle,1,"f_InputClose_1 : "+f_InputClose_1,debugMode);
   logMe(handle,1,"f_InputClose_2 : "+f_InputClose_2,debugMode);
   logMe(handle,1,"f_InputPyram_1 : "+f_InputPyram_1,debugMode);
   logMe(handle,1,"f_InputPyram_2 : "+f_InputPyram_2,debugMode);
   logMe(handle,1,"f_InputPyram_3 : "+f_InputPyram_3,debugMode);
   logMe(handle,1,"f_Mode_SL : "+f_Mode_SL,debugMode);
   logMe(handle,1,"f_Param_SL_1 : "+f_Param_SL_1,debugMode);
   logMe(handle,1,"f_Param_SL_2 : "+f_Param_SL_2,debugMode);
   logMe(handle,1,"f_Coef_ATR_SL_Min : "+f_Coef_ATR_SL_Min,debugMode);
   logMe(handle,1,"f_SL_Margin : "+f_SL_Margin,debugMode);
   logMe(handle,1,"f_Risque_Max_Val : "+f_Risque_Max_Val,debugMode);
   logMe(handle,1,"f_Risque_Pct : "+f_Risque_Pct,debugMode);
   logMe(handle,1,"f_Mode_Trailing : "+f_Mode_Trailing,debugMode);
   logMe(handle,1,"f_PourCent_Close : "+f_PourCent_Close,debugMode);
   logMe(handle,1,"f_Param_Trail_1 : "+f_Param_Trail_1,debugMode);
   logMe(handle,1,"f_Param_Trail_2 : "+f_Param_Trail_2,debugMode);
   logMe(handle,1,"f_PourCent_Pyram : "+f_PourCent_Pyram,debugMode);
   logMe(handle,1,"f_MovingTP : "+f_MovingTP,debugMode);
   logMe(handle,1,"f_Strat_GoalTP : "+f_Strat_GoalTP,debugMode);
   logMe(handle,1,"f_ModeClose : "+f_ModeClose,debugMode);
   logMe(handle,1,"f_useStack : "+f_useStack,debugMode);

   return 1;

  }

//+------------------------------------------------------------------+
