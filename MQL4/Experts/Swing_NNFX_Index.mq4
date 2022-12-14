//+---------------------------------------------------------------------+
//|                                                Swing_NNFX_Index.mq4 |
//|                                                      Version 1.0    |
//|                                                      Benoit Durand  |
//| Expert advisor for No Nonsense Forex style                          |
//| specialized  for index like DAX                                     |
//| According to the strategy, can open and mangage several trades      |
//| Manage trailing stop and exits depending on strategies              |
//| Can pyramid with NNFX's way or DMT's way                            |
//| Efficient context  : Mainly tested with DAX and M30 timeframe       |
//|                                                                     |
//+---------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property strict // lot of warnings at compilation... 

#include <stdlib.mqh>
#include <FileManagement.mqh>
#include <MoneyManagement.mqh>
#include <EASupport.mqh>
#include <Conversions.mqh>
#include <OrderObject.mqh>
#include <APIIndicators.mqh>

input string I_Open_Time_1="315-2100"; //Start-End of robot activating to search for entry points
input bool I_Retest=false; // If we retest entry during the day looking for good entry point
input int I_Mode_Entry=0; //Entry mode : 0="wait candle's close" 1="enter the day of the candle" 2="both"
input string I_Period="D1"; //Time unit to calculate indicators
input string I_Input_BaseLine="MMS2_close_sens:1,20,1";// Baseline indicator
input string I_Check_Distance_BL="Distance_BL_Go:MMS$20#0,1440,14,1";//if we need to check price is not too far from BL
input string I_Check_Cross_BL="MMS2_close_go:1,20,1,1";// Baseline check cross indicator
input string I_Input_Conf_1="BullsVsBears_Go:14,0.01,#SHIFT-1-7,1";// Confirmation indicator 1
input string I_Input_Conf_2="Aroon_Direction:14,1";// Confirmation indicator 2
input string I_Input_Volatility="WAE_En_Cours:150,15,15,0";// Volatility indicator
input string I_Input_Exit_1="SSL_Channel_Go:10,1,1";// Exit indicator 1
input string I_Input_Exit_2="";// Exit indicator 2
input int I_Mode_SL=1; //mode for SL 0="lowest on n candles" 1="ATR"
input string I_Nb_Cand_SL=14; // mode 0 : nb cadles mode 1 param of ATR
input double I_Coef_ATR_SL=1.5; // coef of SL in mode 1
input double I_Coef_ATR_SL_Min=1.5; // if we need a minimal SL for safety I_SL_Min*ATR_4H(12)
input double I_Risque_Max_Val=50; // max risk in absolute
input double I_Risque_Pct=5; //risk in %
input int I_Mode_Trailing=1;// trailing mode with ATR (0 high/low,1 ATR,2 fix)
input double I_Coef_ATR_Trailing=2.0;// coef of trailing with ATR
input int I_PourCent_Close=100; // % of the position to close
input int  I_PourCent_Pyram=50;//% of risk to scale in
input double I_Spread_Limit=600.0; // max spread to enter
input int I_Debug_Mode=1; // debug mode 0="no debug log" 1="debug logs activated"
input int I_Prefixe_Magic=1500000;//prefix magic number to change for every advisor
input bool I_MovingTP=false;// do we move TP when SL moves
input int I_BaseTP=10000; // points to calculate fix TP
input string I_Strat_GoalTP="66-BE*66-50"; // Money management strategy, exit calculated from R ex : 50-BE*100-40-200-30
input bool I_isBackTest=false;//if it's a backtest
input int I_ModeClose=2;// Exit mode : 0 no exit, 1 exit only if winning, 2 exit even if losing
input bool I_useStack=false;// if we scale in position
input string I_Input_Stack_1="";// Scale in indicator 1
input int I_BTScenario=1;// backtest scenario to load from file
input string I_BTFile=""; // File name with the scenarii
input int I_Mode_BL=false;// Base Line mode 0: no BL 1:full 2-7: partial see below
input bool I_Bypass_Log=false; // do not print logs in a comment file
input bool I_Continuation=false; // use continuation trades
input string I_Direction_filter="";// "BUY" / "SELL / "BOTH" if we filter the order type with only one direction

/*0 = by pass BL (warning it's inverted compared to the bool)
1 = normal : full
2= only distance
3=distance and exit
4=entry
5=entry and exit
6=entrt and distance
7=only the trend*/

datetime now,candl_t,preTime,thisHour,thisHalfHour,thisDay,this4Hour,dateLastClose,dateLastOpen,dateLastAllege,thisPeriod;

double p_nor,monTP=I_BaseTP,monTP1=0.0,monTP2=0.0,monTP3=0.0,TP,SL,monLot=0.0,monLot1=0.0,monLot2=0.0,monLot3=0.0,risqueMax=0.0,risque=0.0,risqueMaxPaire=0.0,
             ATR,f_Coef_ATR_SL,f_Coef_ATR_SL_Min,f_Risque_Max_Val,f_Risque_Pct,f_Coef_ATR_Trailing,f_Spread_Limit,risqueEnCours,
             indic_bl=0.0,indic_bl_cross=0.0,indic_open=0.0,indic_exit=0.0,indic_c1=0.0,indic_c2=0.0,indic_vol=0.0;

int ticket,h_log,h_com,h_bt,h_open,tryOrder,intPeriod=0,nbOrdresEnCours=0,nbOrdresFermes=0,magic=0,heureOuvert=0,openHour,
                                            f_Period_MT4=1440,f_Mode_Entry=0,f_Mode_SL=0,stratTP1=0,stratSizeTP1=0,stratTP2=0,stratSizeTP2=0,stratBE=0,
                                            f_Mode_Trailing=0,f_Debug_Mode=0,f_Prefixe_Magic=0,f_BTScenario=0,f_BaseTP=500,f_PourCent_Close=75,f_PourCent_Pyram=100,f_ModeClose=0,goContinuation=0,f_Mode_BL=0;

bool prems=true,ordreOuvert=false,nouvBar=false,trailInfotoLog=false,f_isBackTest,f_MovingTP,f_useStack,f_Continuation=false,
     newDay,newHour,newHalfHour,f_Check_RSI_1d,allege,new4Hour,f_useAllegement=true,goExit=false,f_Retest=false,goRetest=false,closeDone=false,newPeriod=false;

string prefixeFile="Swing_NNFX_Index",fixeCommentFile="",fixeOrderFile="",fixeOpenFile="",openFileName="",fixeSuffixeFile=".csv",f_Period="",labelRobot="NNFX",
       f_Open_Time_1="",f_Open_Time_2="",f_SeuilSecu_Trailing="",f_BTFile="",signal="",f_Lot_Min_Max="",
       f_Input_BaseLine="",f_Check_Distance_BL="",f_Check_Cross_BL="",f_Input_Conf_1="",f_Input_Conf_2="",f_Input_Volatility="",f_Input_Exit_1="",f_Input_Exit_2="",f_Input_Stack_1="",
       f_Strat_GoalTP="",trend_1d="no trend",name,libTrend="",f_Nb_Cand_SL="0",f_Direction_filter="",
       openTimeStart="",openTimeEnd="",openTimeStart_2="",openTimeEnd_2="",exit="", msg="", msgLog="",heureCloture="",nowStr=""
                                    ;

//market param
double minLot = MarketInfo(Symbol(),MODE_MINLOT);
double maxLot = MarketInfo(Symbol(),MODE_MAXLOT);
double stepLot = MarketInfo(Symbol(),MODE_LOTSTEP);
double distMin = MarketInfo(Symbol(),MODE_STOPLEVEL);
double spread=MarketInfo(Symbol(),MODE_SPREAD);

double etatRisque[4],PRO,LOS,RSK,RATIO; // for logs

OrderSelection* myOrdersBook; // init order book
OrderWorker* myOrderWorker;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

   dateLastClose="2015.01.01";// init at 2015 to start

   setFinalInput();   //copy input in variables used by the EA

   fixeOrderFile+=prefixeFile+"_"+f_Period+"_OrderLog"; // init log files
   fixeCommentFile=prefixeFile+"_"+f_Period+"_Com";
   fixeOpenFile=prefixeFile+"_"+f_Period+"_OpenLog";
   labelRobot+=" "+f_Period+" "+f_Direction_filter;

   /* ************************************************/
   /* FORK for backtests                     **********/
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

      if(IsTesting())
        {
         openFileName=getFileNameGlobal(fixeOpenFile,fixeSuffixeFile);
         if(FileIsExist(openFileName))
           {
            FileDelete(openFileName);
           }
         h_open=openTXTWriteFile(openFileName);
        }
      else
        {
         openFileName=getFileNameGlobal(fixeOpenFile,fixeSuffixeFile);
         h_open=openTXTWriteFile(openFileName);
         FileSeek(h_open,0, SEEK_END);
        }
      logInputs(h_com,f_Debug_Mode);
     }
   /****** end if backtest ****/

//Conversion of the input period
   intPeriod=ConvertPeriodStrToInt(f_Period);

//Split open time
   string resSplitOpenTime[];
   StringSplit(f_Open_Time_1,StringGetCharacter("-",0),resSplitOpenTime);
   openTimeStart=resSplitOpenTime[0];
   openTimeEnd=resSplitOpenTime[1];

   if(f_Mode_Entry==2)
     {
      string resSplitOpenTime_2[];
      StringSplit(f_Open_Time_2,StringGetCharacter("-",0),resSplitOpenTime_2);
      openTimeStart_2=resSplitOpenTime_2[0];
      openTimeEnd_2=resSplitOpenTime_2[1];
     }

   f_Period_MT4=ConvertPeriodStrToInt(f_Period);

   logMe(h_com,0," UT : "+f_Period+"="+f_Period_MT4 + " opening window 1 from  "+openTimeStart+" to "+openTimeEnd+" opening window 1 from "+openTimeStart_2+" to "+openTimeEnd_2,1);

   /* *************************************************/
   /*split the money management strategy              */
   /*f_Strat_GoalTP ex : 50-BE;100-35-200-30$1900     */
   /*50-BE = at 50% of SL we move SL to breakeven     */
   /*100 = TP1 at 100% of SL                          */
   /*35 = % of size to exit at TP1                    */
   /*200 = TP2 at 200% of SL                          */
   /*30 = % of size to exit at TP2 TP2                */
   /*$1900 = Time to close all trades                 */
   string resultSplitPre[],resultSplitBE[],resultSplitStrat[],resultSplitCLot[];

   if(StringFind(f_Strat_GoalTP,"$",0)>=0)// if there is an exit hour
     {
      StringSplit(f_Strat_GoalTP,StringGetCharacter("$",0),resultSplitCLot);
      heureCloture=resultSplitCLot[1];
      f_Strat_GoalTP=resultSplitCLot[0];
     }

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
      logMe(h_com,0," Strat TP : Size 1="+stratSizeTP1 + " for "+stratTP1+"% of SL and size 2="+stratSizeTP2+" for "+stratTP2+"% of SL and BE="+stratBE+"% of SL exit:"+heureCloture,1);
     }


   ObjectsDeleteAll(-1,OBJ_ARROW);
   ObjectsDeleteAll(-1,OBJ_TEXT);

   preTime=TimeCurrent();

   intPeriod=ConvertPeriodStrToInt(f_Period);

   Verif(minLot,maxLot,distMin,stepLot,0,monLot,0);
   magic=GetMagicNumber(f_Prefixe_Magic,intPeriod); // set magic number


   writeHeaderOrderLog(h_log,";",f_Debug_Mode); // init order log file
   logMe(h_com,0,"START Swing NNFX Index Magic : "+magic,f_Debug_Mode);
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
   nowStr=TimeToStr(now,TIME_MINUTES);
   StringReplace(nowStr,":","");
   spread=MarketInfo(Symbol(),MODE_SPREAD);

   UpdateMyOrderBook();
   nbOrdresEnCours=myOrdersBook.Count();
   nbOrdresFermes=0;
   ordreOuvert=false;

//store date of day for some logs
   if(thisDay!=iTime(Symbol(),PERIOD_D1,0))
     {
      trailInfotoLog=true;
      thisDay=iTime(Symbol(),PERIOD_D1,0);   //new day
      logMe(h_com,0,"Daily Account Balance = "+AccountBalance(),f_Debug_Mode);

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

   if(thisPeriod==iTime(Symbol(),intPeriod,0))
     {
      newPeriod=false;
     }
   else
     {
      newPeriod=true;
      thisPeriod=iTime(Symbol(),intPeriod,0);
      newDay=true;
      goRetest=false;
      closeDone=false;
     }

   openHour=GoodTime(1,openTimeStart,openTimeEnd);
   if(openHour==-1)
     {
      logMe(h_com,8,"Erreur while GoodTime Mode 1 Symbol "+Symbol()+" Begin "+openTimeStart+" End "+openTimeEnd,f_Debug_Mode);
     }

   if(f_Mode_Entry==2 && openHour==0)
     {
      openHour=GoodTime(1,openTimeStart_2,openTimeEnd_2);
      if(openHour==-1)
        {
         logMe(h_com,8,"Erreur while second GoodTime Mode 1 Symbol "+Symbol()+" Begin "+openTimeStart_2+" End "+openTimeEnd_2,f_Debug_Mode);
        }
     }

   /****************************
   *** TRADE MANAGEMENT *******
   ****************************/
   if(myOrdersBook.Count()>0  && newPeriod)
     {
      string direction="";
      if(myOrdersBook.Get(0).sens>0)
        {
         direction="BUY";
        }
      else
        {
         direction="SELL";
        }
      double openPrice=myOrdersBook.Get(0).openPrice;

      newDay=false; // avoid case trade is killed during openingtime and bot go in just after

      /****************************
      *** TRAILING STOP *******
      ****************************/
      for(int i=OrdersTotal(); i>=0; i--) // for each order, check SL and exit if needed
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
              {
               //check trailing stop
               int resModify=0;
               TP=OrderTakeProfit();

               //case strat BE
               if(stratBE>0)
                 {
                  double openSL=getOpenSL(h_open,myOrdersBook.Get(0).ticket,h_com); // get SL of the position's opening
                  if(openSL==0.0)
                    {
                     openSL= myOrdersBook.Get(0).openStopLoss;
                    }

                  double marginSL=100.0*Point;
                  if(direction=="BUY")
                    {
                     if((Ask-openPrice>(stratBE/100.0)*(openPrice-openSL)) && OrderStopLoss()<openPrice)
                       {
                        logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Ask="+Ask+", open="+openPrice+" marginSL="+marginSL+" openSL="+openSL,f_Debug_Mode);
                        resModify=ModifySL(OrderTicket(),openPrice+marginSL, TP,50.0, h_log,h_com,f_Debug_Mode);
                        if(resModify>0)
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Go BE because Ask="+Ask+" and open="+openPrice,f_Debug_Mode);
                          }
                        else
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Error going BE",f_Debug_Mode);
                          }
                       }
                    }
                  else
                    {
                     if((openPrice-Bid>(stratBE/100.0)*(openSL-openPrice)) && OrderStopLoss()>openPrice)
                       {
                        resModify=ModifySL(OrderTicket(),openPrice-marginSL, TP,50.0,h_log,h_com,f_Debug_Mode);
                        if(resModify>0)
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Go BE because Bid="+Bid+" and open="+openPrice,f_Debug_Mode);
                          }
                        else
                          {
                           logMe(h_com,0,"TRAIL MODE BE Ticket "+OrderTicket()+" Error going BE",f_Debug_Mode);
                          }

                       }

                    }
                 }

               if(f_Mode_Trailing==1) // trailing mode ATR
                 {
                  ATR=ATRinPoints(Symbol(),StringToInteger(f_Nb_Cand_SL),intPeriod);
                  if(ATR*f_Coef_ATR_SL<f_Coef_ATR_SL_Min)
                    {
                     ATR=f_Coef_ATR_SL_Min/f_Coef_ATR_SL;
                    }

                  TrailingStop(OrderTicket(),(ATR*f_Coef_ATR_Trailing),(ATR*f_Coef_ATR_SL),h_com,f_Debug_Mode,h_log,f_MovingTP,trailInfotoLog); //TrailingStop(ATR*f_Coef_Trailing,ATR*f_Coef_ATR_SL);
                  trailInfotoLog=false;
                  logMe(h_com,1,"TrailingStopTicket : order updated mode 1.",f_Debug_Mode);
                  // writeCommentLog(h_com,0,"TR OK",f_Debug_Mode);// trace le démarrage
                 }
               else
                 {
                  if(f_Mode_Trailing==2)// trailing mode fix
                    {
                     TrailingStop(OrderTicket(),f_Coef_ATR_Trailing,f_Coef_ATR_SL,h_com,f_Debug_Mode,h_log,f_MovingTP,trailInfotoLog); //TrailingStop(ATR*f_Coef_Trailing,ATR*f_Coef_ATR_SL);
                     trailInfotoLog=false;
                    }
                  else
                    {
                     if(f_Mode_Trailing==0)// trailing mode lowest
                       {

                        SL=getDeltaSL(direction,intPeriod,f_Mode_SL,f_Nb_Cand_SL,f_Coef_ATR_SL,h_com);
                        if(new4Hour)
                          {
                           logMe(h_com,0,"TRAIL MODE 0 Size raw SL "+SL+ " f_SL_Min*ATR(14)"+f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod,142,1),f_Debug_Mode);
                          }

                        //at least 2 ATR(14)
                        if(SL<f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod,14,1))
                          {
                           SL=f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod,14,1);
                           if(new4Hour)
                             {
                              logMe(h_com,0,"TRAIL MODE 0 Size SL update "+SL,f_Debug_Mode);
                             }
                          }

                        SL=SL+(100.0*Point); // + 10 pips for safety
                        if(direction=="BUY")
                          {
                           if(f_MovingTP)
                             {
                              TP=TP+(I_BaseTP*Point);
                             }
                           resModify=ModifySL(OrderTicket(),Bid-SL, TP,50.0, h_log,h_com,f_Debug_Mode);
                          }
                        else
                          {
                           if(f_MovingTP)
                             {
                              TP=TP-(I_BaseTP*Point);
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
                  logMe(h_com,9,"TrailingStopTicket : error while order's update.",f_Debug_Mode);
                 }
               UpdateMyOrderBook();
              }
           }
        }//end for

      /***********************/
      /*** CLOSE      ********/
      /***********************/
      if((f_ModeClose>0 && !closeDone /*&& openHour==1*/) || (heureCloture!="" && nowStr>=heureCloture))
        {

         //Test si on est plus du bon côté de la BL, si le C1 s'est retourné ou si l'indicateur de sortie s'est confirmée

         double duree=now-OrderOpenTime(); //on garde l'ordre ouvert au moins 8h
         goExit=false;
         closeDone=true;
         exit="";
         msg="";
         msgLog=""; // reset
         int tmp_pourcentClose=f_PourCent_Close;
         logMe(h_com,1,"Duree="+duree+" now="+nowStr+" cloture="+heureCloture,f_Debug_Mode);

         if(heureCloture!="" && nowStr>=heureCloture) // cloture sur l'heure
           {
            goExit=true;
            tmp_pourcentClose=100;
            logMe(h_com,1,"Heure de cloture "+nowStr,f_Debug_Mode);
           }

         if(!goExit && f_Input_BaseLine!="" && (f_Mode_BL==1 || f_Mode_BL==3 || f_Mode_BL==5))
           {
            indic_bl=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_BaseLine,h_com);
            if(indic_bl==-9999)
              {
               logMe(h_com,9,"ERROR CALCUL Indicator BASELINE "+f_Period_MT4+" "+f_Input_BaseLine,f_Debug_Mode);
              }
            msgLog+="EXIT BL "+indic_bl;
           }
         else
           {
            if(f_Mode_BL==1 || f_Mode_BL==3 || f_Mode_BL==5)
              {
               logMe(h_com,9,"NO BL INDICATOR !! ",f_Debug_Mode);
              }
           }

         if(indic_bl==-9999 || indic_bl==-5555 || indic_bl==-6666)
           {
            indic_bl=0.0;   // check particular cases
           }

         if(direction=="BUY" && indic_bl<0.0)
           {
            goExit=true;
           }
         if(direction=="SELL" && indic_bl>0.0)
           {
            goExit=true;
           }

         if(!goExit && f_Input_Conf_1!="") // check for C1
           {
            indic_exit=getIndicatorFromParam(Symbol(),  f_Period_MT4,replaceConfirmationShift(f_Input_Conf_1,true),h_com);
            if(indic_exit==-9999)
              {
               logMe(h_com,9,"ERROR CALCUL Indicator C1 "+f_Period_MT4+" "+f_Input_Conf_1,f_Debug_Mode);
              }
            if(indic_exit==-9999 || indic_exit==-5555 || indic_exit==-6666)
              {
               indic_exit=0.0;   // check particular cases
              }
            msgLog+=" C1 "+indic_exit;

            if(direction=="BUY" && indic_exit<0.0)
              {
               goExit=true;
              }
            if(direction=="SELL" && indic_exit>0.0)
              {
               goExit=true;
              }
           }

         if(!goExit && f_Input_Exit_1!="") // check for exit indicator
           {
            indic_exit=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_Exit_1,h_com);
            if(indic_exit==-9999)
              {
               logMe(h_com,9,"ERROR CALCUL Indicator Exit "+f_Period_MT4+" "+f_Input_Exit_1,f_Debug_Mode);
              }
            if(indic_exit==-9999 || indic_exit==-5555 || indic_exit==-6666)
              {
               indic_exit=0.0;   // check particular cases
              }
            msgLog+=" Exit "+indic_exit;

            if(direction=="BUY" && indic_exit<0.0)
              {
               goExit=true;
              }
            if(direction=="SELL" && indic_exit>0.0)
              {
               goExit=true;
              }
           }

         if(!goExit && f_Input_Exit_2!="") // check for exit 2 indicator
           {
            indic_exit=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_Exit_2,h_com);
            if(indic_exit==-9999)
              {
               logMe(h_com,9,"ERROR CALCUL Indicator C1 "+f_Period_MT4+" "+f_Input_Exit_2,f_Debug_Mode);
              }
            if(indic_exit==-9999 || indic_exit==-5555 || indic_exit==-6666)
              {
               indic_exit=0.0;   // check particular cases
              }
            msgLog+=" Exit 2 "+indic_exit;

            if(direction=="BUY" && indic_exit<0.0)
              {
               goExit=true;
              }
            if(direction=="SELL" && indic_exit>0.0)
              {
               goExit=true;
              }
           }


         logMe(h_com,1,"CLOSE MODE "+f_ModeClose+"  : "+msgLog,f_Debug_Mode);

         if(goExit /*&& (duree/60)>5.0*/)
           {
            logMe(h_com,1,"CLOSE "+f_PourCent_Close+"% detail : "+msg,f_Debug_Mode);

            // on ferme f_PourCent_Close% de la position
            int nbOrdersClosed=DecreasePosition(myOrdersBook,NormalizeDouble(myOrdersBook.TotalPosition()*(tmp_pourcentClose/100.0),2), h_log,h_com,f_Debug_Mode);
            if(nbOrdersClosed>0)
              {
               logMe(h_com,1,"Close "+nbOrdersClosed+" orders closed.",f_Debug_Mode);
               UpdateMyOrderBook();
               dateLastClose=now;
               dateLastAllege=now;
              }

           }
        }// fin close

      /*********************/
      /*** SCALE IN ********/
      /*********************/
      if(myOrdersBook.Count()<10 && myOrdersBook.Count()>0 && f_useStack  && ((now-dateLastOpen)/3600)>1.0 && openHour==1)  //at least 1 hour after the last entry
        {
         ordreOuvert=true;
         risqueEnCours=myOrdersBook.getRiskToral();
         if(risqueEnCours<f_Risque_Pct)
           {

            spread=MarketInfo(Symbol(),MODE_SPREAD);

            //-------------------------send Orders
            if(openHour==1 && ((direction=="BUY" && Bid>openPrice)  || (direction=="SELL" && Ask<openPrice)))
              {

               bool scaleIn=false;
               double indic_stack_1=-9999;

               if(f_Input_Stack_1!="")
                 {
                  indic_stack_1=getIndicatorFromParam(Symbol(),f_Period_MT4,f_Input_Stack_1,h_com);

                 }

               if(direction=="BUY" && indic_stack_1>0)
                 {
                  scaleIn=true;
                 }
               if(direction=="SELL" && indic_stack_1<0)
                 {
                  scaleIn=true;
                 }

               logMe(h_com,0,"Scale in "+f_Input_Stack_1+" : "+indic_stack_1,f_Debug_Mode);

               if(scaleIn)
                 {

                  SL=MathAbs(Bid-myOrdersBook.Get(0).stopLoss);
                  logMe(h_com,0,"SL of myOrdersBook : "+myOrdersBook.Get(0).stopLoss + " -- define size SL : "+DoubleToStr(SL,5),f_Debug_Mode);

                  // sizing
                  risqueMax=CalculateRisk(f_Risque_Max_Val);// returns risk max in %
                  risqueMax=risqueMax*(f_PourCent_Pyram/100.0); // risk max for pyramiding
                  risque= risqueMax-risqueEnCours;//calculates free risk
                  if(risque>0.0)
                    {
                     monLot=CalculateVol(signal,risque,SL,h_com);

                    }
                  else
                    {
                     monLot=0.0;
                    }

                  if(monLot==0.0)
                    {
                     logMe(h_com,0,"Scale in ko for a risk of "+DoubleToStr(risque,2)+"% and SL at "+DoubleToStr(SL,5),f_Debug_Mode);
                    }

                  monLot=NormalizeDouble(monLot,2);
                  logMe(h_com,0,"Risque ("+DoubleToStr(risque,2)+") risque max("+DoubleToStr(risqueMax,2)+") SL : "+DoubleToStr(SL,5)+" monLot : "+DoubleToStr(monLot,2),f_Debug_Mode);

                  if(SL>0.0 && monLot>0.0)
                    {
                     dateLastOpen=now;

                     monTP=f_BaseTP*Point ;
                     if(monTP<20*SL) //move TP
                       {
                        monTP=20.0*SL;
                       }

                     //split lot
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

                        if(monLot1>0.0) //send orders
                          {
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

                    }//if(SL>0 && monLot>0)
                 }//if(scaleIn)
              }//if(heureOuvert)
           }//risqueEnCours<f_Risque_Pct

        }//myOrdersBook.Count()>0

     }// fin (nbOrdresEnCours>=1)

   /***********************/
   /*** OPENING PROCESS ***/
   /***********************/

   if((newPeriod || goRetest) && openHour==1 && myOrdersBook.Count()==0)//if it's a new period during the good time and without opened order, go
     {
      signal="";
      string myC1indic="";
      if(!f_Continuation)
        {
         goContinuation=0;
        }

      if(goContinuation!=0 && f_Input_BaseLine!="") // RESET OF CONTINUATION VAR
        {
         indic_bl=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_BaseLine,h_com);
         if(indic_bl==-9999)
           {
            logMe(h_com,9,"ERROR calculating Indicator BASELINE "+f_Period_MT4+" "+f_Input_BaseLine,f_Debug_Mode);
           }
         if(indic_bl==-9999 || indic_bl==-5555 || indic_bl==-6666)
           {
            indic_bl=0.0;
           }
         if((goContinuation>0 && indic_bl<=0)||(goContinuation<0 && indic_bl>=0))
           {
            goContinuation=0;
            logMe(h_com,1,"CONTINUATION RESET !! ",f_Debug_Mode);
           }
        }

      libTrend="Continuation "+goContinuation+ " Retest "+goRetest; //reset
      // test of the baseline
      if((f_Check_Distance_BL!="" && (f_Mode_BL==1 || f_Mode_BL==2 || f_Mode_BL==3 || f_Mode_BL==6)) || goContinuation!=0)
        {
         indic_bl=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Check_Distance_BL,h_com);
         if(indic_bl==-9999)
           {
            logMe(h_com,9,"ERROR calculating Indicator BASELINE "+f_Period_MT4+" "+f_Check_Distance_BL,f_Debug_Mode);
           }
         libTrend+=" BL Distance "+indic_bl;
        }
      else  //test BL Side
        {
         if(f_Input_BaseLine!="" && f_Mode_BL>=1)
           {
            indic_bl=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_BaseLine,h_com);
            if(indic_bl==-9999)
              {
               logMe(h_com,9,"ERROR calculating Indicator BASELINE "+f_Period_MT4+" "+f_Input_BaseLine,f_Debug_Mode);
              }
            libTrend+=" BL "+indic_bl;
           }
         else
           {
            if(f_Mode_BL>=1)
              {
               logMe(h_com,9,"NO BL INDICATOR !! ",f_Debug_Mode);
              }
           }
        }

      if(indic_bl==-9999 || indic_bl==-5555 || indic_bl==-6666)
        {
         indic_bl=0.0;   // check particular cases
        }

      // check of the others indicators one after the other
      if(indic_bl!=0.0 || f_Mode_BL==0)
        {
         if(f_Input_Conf_1!="")//check C1
           {
            //replace the shift of input conf 1

            if(f_Check_Cross_BL!="" && (f_Mode_BL==1 || f_Mode_BL==4 || f_Mode_BL==5 || f_Mode_BL==6))
              {
               indic_bl_cross=0.0;
               indic_bl_cross=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Check_Cross_BL,h_com);
               if(indic_bl_cross==-9999)
                 {
                  logMe(h_com,9,"ERROR calculating Indicator CROSS BASELINE "+f_Period_MT4+" "+f_Check_Cross_BL,f_Debug_Mode);
                  indic_bl_cross=0.0;
                 }
               libTrend+=" BL Cross "+indic_bl_cross;
              }
            else
              {
               if(f_Mode_BL==1 || f_Mode_BL==4 || f_Mode_BL==5 || f_Mode_BL==6)
                 {
                  logMe(h_com,9,"NO BL CROSS INDICATOR !! ",f_Debug_Mode);
                 }
              }

            if(goContinuation==0 && (indic_bl_cross!=0.0 || f_Check_Cross_BL==""))
              {
               myC1indic=replaceConfirmationShift(f_Input_Conf_1,false);
              }
            else
              {
               myC1indic=replaceConfirmationShift(f_Input_Conf_1,true);
              }

            indic_c1=getIndicatorFromParam(Symbol(),  f_Period_MT4,myC1indic,h_com);
            if(indic_c1==-9999)
              {
               logMe(h_com,9,"ERROR calculating Indicator C1 "+f_Period_MT4+" "+f_Input_Conf_1,f_Debug_Mode);
              }
            if(indic_c1==-9999 || indic_c1==-5555 || indic_c1==-6666)
              {
               indic_c1=0.0;   // check particular cases
              }
            libTrend+=" C1 "+myC1indic+" "+indic_c1;

            if((indic_bl>=0 && indic_c1>0) || (indic_bl<=0 && indic_c1<0))
              {
               indic_open=indic_c1;

               if(f_Input_Conf_2!="") // check C2
                 {
                  indic_c2=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_Conf_2,h_com);
                  if(indic_c2==-9999)
                    {
                     logMe(h_com,9,"ERROR calculating Indicator C2 "+f_Period_MT4+" "+f_Input_Conf_2,f_Debug_Mode);
                    }
                  if(indic_c2==-9999 || indic_c2==-5555 || indic_c2==-6666)
                    {
                     indic_c2=0.0;   // check particular cases
                    }
                  libTrend+=" C2 "+indic_c2;

                  if((indic_open>0 && indic_c2>0) || (indic_open<0 && indic_c2<0))
                    {
                     if(f_Input_Volatility!="") // check Vol
                       {
                        indic_vol=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_Volatility,h_com);
                        if(indic_vol==-9999)
                          {
                           logMe(h_com,9,"ERROR calculating Indicator VOL "+f_Period_MT4+" "+f_Input_Volatility,f_Debug_Mode);
                          }
                        if(indic_vol==-9999 || indic_vol==-5555 || indic_vol==-6666)
                          {
                           indic_vol=0.0;   // check particular cases
                          }
                        libTrend+=" Vol "+indic_vol;

                        if(indic_vol>0 || goContinuation!=0) //vol is only positive
                          {
                           if(f_Input_Exit_1!="") // check Exit
                             {
                              indic_exit=getIndicatorFromParam(Symbol(),  f_Period_MT4,f_Input_Exit_1,h_com);
                              if(indic_exit==-9999)
                                {
                                 logMe(h_com,9,"ERROR calculating Indicator EXIT "+f_Period_MT4+" "+f_Input_Exit_1,f_Debug_Mode);
                                }
                              if(indic_exit==-9999 || indic_exit==-5555 || indic_exit==-6666)
                                {
                                 indic_exit=0.0;   // check particular cases
                                }
                              libTrend+=" Exit "+indic_exit;

                              if((indic_open>0 && indic_exit>=0) || (indic_open<0 && indic_exit<=0))
                                {
                                 if(indic_open>0)
                                   {
                                    signal="BUY";
                                   }
                                 if(indic_open<0)
                                   {
                                    signal="SELL";
                                   }
                                 libTrend+=" SIGNAL "+signal;
                                }
                              else
                                {
                                 libTrend+=" NO SIGNAL !";
                                }
                             }
                           else
                             {
                              logMe(h_com,9,"NO EXIT INDICATOR !! ",f_Debug_Mode);
                             }
                          }
                        else
                          {
                           libTrend+=" Reject on Vol indic";
                          }
                       }
                     else
                       {
                        logMe(h_com,9,"NO VOLATILITY INDICATOR !! ",f_Debug_Mode);
                       }
                    }
                  else
                    {
                     libTrend+=" Reject on C2 indic";
                    }
                 }
               else
                 {
                  logMe(h_com,9,"NO C2 INDICATOR !! ",f_Debug_Mode);
                 }
              }
            else
              {
               libTrend+=" Reject on C1 indic";
              }

           }
         else
           {
            logMe(h_com,9,"NO C1 INDICATOR !! ",f_Debug_Mode);
           }
        }
      else
        {
         libTrend+=" Reject on BL indic";
         if(f_Retest)
           {
            goRetest=true;
           }
        }

      if(goContinuation!=0)
        {
         libTrend+=" CONTINUATION TRADE !! ";
        }

      logMe(h_com,1,libTrend,f_Debug_Mode);
      DisplayTextLeftCorner("Info",labelRobot+" "+libTrend);


      /*** SEND ORDERS ***/
      if((signal=="BUY" && f_Direction_filter!="SELL") || (signal=="SELL" && f_Direction_filter!="BUY"))
        {
         SL=getDeltaSL(signal,intPeriod,f_Mode_SL,f_Nb_Cand_SL,f_Coef_ATR_SL,h_com);
         //at least SL = 2 ATR(14)
         double SL_min=f_Coef_ATR_SL_Min*iATR(Symbol(), intPeriod,14,1);
         if(SL<SL_min)
           {
            logMe(h_com,0,"SL "+SL+" <"+f_Coef_ATR_SL_Min+"*iATR(14)*Point "+SL_min,f_Debug_Mode);
            SL=SL_min;
           }

         SL=SL+(500.0*Point); // adds 5 pips for security and spread

         risqueMaxPaire=checkOrderCurrency(Symbol(),f_Risque_Pct*2.0, h_com,4); //max risk if there are orders with the same currency but othe pair

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

         monLot=CalculateVol(signal,risque,SL,h_com);
         if(monLot==0.0)
           {
            logMe(h_com,0,"Lot KO, double risk, risk : "+risque*2+"%",f_Debug_Mode);
            risque=risque*2;
            if(risque>risqueMax)
              {
               risque=risqueMax;
              }
            monLot=CalculateVol(signal,risque,SL,h_com);

           }

         logMe(h_com,0,"Risk max("+risqueMax+") SL : "+SL+" monLot : "+monLot,f_Debug_Mode);

         monTP=f_BaseTP*Point ;
         if(monTP<20*SL) // at least TP at 20 SL
           {
            monTP=20.0*SL;
           }

         //split lot according to strat
         if(stratTP1>0)
           {
            monLot1=0.0;
            monLot2=0.0;
            monLot3=0.0;
            monTP1=monTP;
            monTP2=monTP;
            monTP3=monTP;
            monLot1=SplitOrderStrat(monLot,stratSizeTP1,h_com,f_Debug_Mode); //
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
               // send orders
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
         else  // no strat
           {
            ticket=sendOrder(magic,signal,labelRobot+" Open",SL,monLot,monTP,etatRisque,h_com,h_log,f_Debug_Mode,h_open);
            if(ticket<0)
              {
               logMe(h_com,9,"ORDER SENT KO !!",f_Debug_Mode);
              }
           }
         UpdateMyOrderBook();
         logMe(h_com,0,"Order book :"+myOrdersBook.PrintOrderSelection(),f_Debug_Mode);
         dateLastOpen=now;//used to block multi order
         if(signal=="BUY")
           {
            goContinuation=1;
           }
         else
           {
            goContinuation=-1;
           }
         goRetest=false;
        }

      newDay=false;

     }
   Sleep(1000);
  }
//+----------------------------------------------------------------+
//+-------------------- END MAIN ALGO  ----------------------------+
//+----------------------------------------------------------------+


//In a confirmation API indicator string replaces the shift tag (e.g. #SHIFT-1-7) by the true shift
//#SHIFT-default shift-bridge shift
//sourceIndic : source string, isDefault : if returns default shift
string replaceConfirmationShift(const string sourceIndic,const bool isDefault)
  {
   string newIndic=sourceIndic, oldTag="",shift="";
   string resMethode[], resParam[],resTag[], listParam="";
   bool goReplace=false;

   if(StringSplit(sourceIndic,StringGetCharacter(":",0),resMethode)==2)
     {
      listParam=resMethode[1];

      if(StringSplit(listParam,StringGetCharacter(",",0),resParam)>0)
        {
         for(int i=0; i<ArraySize(resParam); i++)
           {
            if(StringFind(resParam[i],"#SHIFT",0)>=0)
              {
               oldTag=resParam[i];
               if(StringSplit(oldTag,StringGetCharacter("-",0),resTag)>0)
                 {
                  if(ArraySize(resTag)==3)
                    {
                     if(isDefault)
                       {
                        shift=resTag[1];
                       }
                     else
                       {
                        shift=resTag[2];
                       }
                     StringReplace(newIndic,oldTag,shift);
                    }
                 }

              }
           }

        }
     }
   return newIndic;
  }


//ResetOrderBook : drop/create of an order book
// return 0
int ResetOrderBook()
  {
   delete(myOrdersBook); // on le nettoie
   myOrdersBook=NULL;
   myOrdersBook=myOrderWorker.GetOpen(magic,Symbol()); //init the OrderWOrker
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
   f_Open_Time_1=I_Open_Time_1;
   f_Retest=I_Retest;
   f_Mode_Entry=I_Mode_Entry;
   f_Period=I_Period;
   f_Mode_BL=I_Mode_BL;
   f_Input_BaseLine=I_Input_BaseLine;
   f_Check_Distance_BL=I_Check_Distance_BL;
   f_Check_Cross_BL=I_Check_Cross_BL;
   f_Input_Conf_1=I_Input_Conf_1;
   f_Input_Conf_2=I_Input_Conf_2;
   f_Input_Volatility=I_Input_Volatility;
   f_Input_Exit_1=I_Input_Exit_1;
   f_Input_Exit_2=I_Input_Exit_2;
   f_Mode_SL=I_Mode_SL;
   f_Nb_Cand_SL=I_Nb_Cand_SL;
   f_Coef_ATR_SL=I_Coef_ATR_SL;
   f_Coef_ATR_SL_Min=I_Coef_ATR_SL_Min;
   f_Risque_Max_Val=I_Risque_Max_Val;
   f_Risque_Pct=I_Risque_Pct;
   f_Mode_Trailing=I_Mode_Trailing;
   f_Coef_ATR_Trailing=I_Coef_ATR_Trailing;
   f_PourCent_Close=I_PourCent_Close;
   f_PourCent_Pyram=I_PourCent_Pyram;
   f_Spread_Limit=I_Spread_Limit;
   f_Debug_Mode=I_Debug_Mode;
   f_Prefixe_Magic=I_Prefixe_Magic;
   f_MovingTP=I_MovingTP;
   f_BaseTP=I_BaseTP;
   f_Strat_GoalTP=I_Strat_GoalTP;
   f_isBackTest=I_isBackTest;
   f_ModeClose=I_ModeClose;
   f_useStack=I_useStack;
   f_Input_Stack_1=I_Input_Stack_1;
   f_BTScenario=I_BTScenario;
   f_BTFile=I_BTFile;
   f_Continuation=I_Continuation;
   f_Direction_filter=I_Direction_filter;

   return 1;
  }

//set variabels f_ with inputs from scenarii file
//monTab = an array with the data of the scenario
int setScenarioBacktest(const string &monTab[],const int handle=0,const int debugMode=0)
  {
   if(ArraySize(monTab)>0)
     {
      logMe(handle,6,"Loading scenario "+monTab[0]+" - "+monTab[1],debugMode);
      f_BTScenario=monTab[0];
      f_Open_Time_1=monTab[2];
      logMe(handle,1,"f_Open_Time_1 : "+f_Open_Time_1,debugMode);
      if(IsBool(monTab[3]))
        {
         f_Retest=StringToBool(monTab[3]);
         logMe(handle,1,"f_Retest : "+f_Retest,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Retest : "+monTab[3],debugMode);
        }
      if(IsInteger(monTab[4]))
        {
         f_Mode_Entry=StringToInteger(monTab[4]);
         logMe(handle,1,"f_Mode_Entry : "+f_Mode_Entry,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_Entry : "+monTab[4],debugMode);
        }
      f_Period=monTab[5];
      logMe(handle,1,"f_Period : "+f_Period,debugMode);
      f_Input_BaseLine=monTab[6];
      logMe(handle,1,"f_Input_BaseLine : "+f_Input_BaseLine,debugMode);
      f_Check_Distance_BL=monTab[7];
      logMe(handle,1,"f_Check_Distance_BL : "+f_Check_Distance_BL,debugMode);
      f_Check_Cross_BL=monTab[8];
      logMe(handle,1,"f_Check_Cross_BL : "+f_Check_Cross_BL,debugMode);
      f_Input_Conf_1=monTab[9];
      logMe(handle,1,"f_Input_Conf_1 : "+f_Input_Conf_1,debugMode);
      f_Input_Conf_2=monTab[10];
      logMe(handle,1,"f_Input_Conf_2 : "+f_Input_Conf_2,debugMode);
      f_Input_Volatility=monTab[11];
      logMe(handle,1,"f_Input_Volatility : "+f_Input_Volatility,debugMode);
      f_Input_Exit_1=monTab[12];
      logMe(handle,1,"f_Input_Exit_1 : "+f_Input_Exit_1,debugMode);
      f_Input_Exit_2=monTab[13];
      logMe(handle,1,"f_Input_Exit_2 : "+f_Input_Exit_2,debugMode);

      if(IsInteger(monTab[14]))
        {
         f_Mode_SL=StringToInteger(monTab[14]);
         logMe(handle,1,"f_Mode_SL : "+f_Mode_SL,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_SL : "+monTab[14],debugMode);
        }
      f_Nb_Cand_SL=monTab[15];
      logMe(handle,1,"f_Nb_Cand_SL : "+f_Nb_Cand_SL,debugMode);
      if(IsNumber(monTab[16]))
        {
         f_Coef_ATR_SL=StringToDouble(monTab[16]);
         logMe(handle,1,"f_Coef_ATR_SL : "+f_Coef_ATR_SL,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Coef_ATR_SL : "+monTab[16],debugMode);
        }
      if(IsNumber(monTab[17]))
        {
         f_Coef_ATR_SL_Min=StringToDouble(monTab[17]);
         logMe(handle,1,"f_Coef_ATR_SL_Min : "+f_Coef_ATR_SL_Min,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Coef_ATR_SL_Min : "+monTab[17],debugMode);
        }
      if(IsNumber(monTab[18]))
        {
         f_Risque_Max_Val=StringToDouble(monTab[18]);
         logMe(handle,1,"f_Risque_Max_Val : "+f_Risque_Max_Val,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Risque_Max_Val : "+monTab[18],debugMode);
        }
      if(IsNumber(monTab[19]))
        {
         f_Risque_Pct=StringToDouble(monTab[19]);
         logMe(handle,1,"f_Risque_Pct : "+f_Risque_Pct,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Risque_Pct : "+monTab[19],debugMode);
        }
      if(IsInteger(monTab[20]))
        {
         f_Mode_Trailing=StringToInteger(monTab[20]);
         logMe(handle,1,"f_Mode_Trailing : "+f_Mode_Trailing,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_Trailing : "+monTab[20],debugMode);
        }
      if(IsNumber(monTab[21]))
        {
         f_Coef_ATR_Trailing=StringToDouble(monTab[21]);
         logMe(handle,1,"f_Coef_ATR_Trailing : "+f_Coef_ATR_Trailing,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Coef_ATR_Trailing : "+monTab[21],debugMode);
        }
      if(IsInteger(monTab[22]))
        {
         f_PourCent_Close=StringToInteger(monTab[22]);
         logMe(handle,1,"f_PourCent_Close : "+f_PourCent_Close,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_PourCent_Close : "+monTab[22],debugMode);
        }
      if(IsInteger(monTab[23]))
        {
         f_PourCent_Pyram=StringToInteger(monTab[23]);
         logMe(handle,1,"f_PourCent_Pyram : "+f_PourCent_Pyram,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_PourCent_Pyram : "+monTab[23],debugMode);
        }
      if(IsBool(monTab[24]))
        {
         f_MovingTP=StringToBool(monTab[24]);
         logMe(handle,1,"f_MovingTP : "+f_MovingTP,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_MovingTP : "+monTab[24],debugMode);
        }
      f_Strat_GoalTP=monTab[25];
      logMe(handle,1,"f_Strat_GoalTP : "+f_Strat_GoalTP,debugMode);
      if(IsInteger(monTab[26]))
        {
         f_ModeClose=StringToInteger(monTab[26]);
         logMe(handle,1,"f_ModeClose : "+f_ModeClose,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_ModeClose : "+monTab[26],debugMode);
        }
      if(IsBool(monTab[27]))
        {
         f_useStack=StringToBool(monTab[27]);
         logMe(handle,1,"f_useStack : "+f_useStack,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_useStack : "+monTab[27],debugMode);
        }
      f_Input_Stack_1=monTab[28];
      logMe(handle,1,"f_Input_Stack_1 : "+f_Input_Stack_1,debugMode);
      f_Direction_filter=monTab[29];
      logMe(handle,1,"f_Direction_filter : "+f_Direction_filter,debugMode);
      if(IsBool(monTab[30]))
        {
         f_Continuation=StringToBool(monTab[30]);
         logMe(handle,1,"f_Continuation : "+f_Continuation,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Continuation : "+monTab[30],debugMode);
        }
      if(IsNumber(monTab[31]))
        {
         f_Mode_BL=StringToDouble(monTab[31]);
         logMe(handle,1,"f_Mode_BL : "+f_Mode_BL,debugMode);
        }
      else
        {
         logMe(handle,9,"Error loading f_Mode_BL : "+monTab[31],debugMode);
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
   logMe(handle,1,"f_Open_Time_1 : "+f_Open_Time_1,debugMode);
   logMe(handle,1,"f_Retest : "+f_Retest,debugMode);
   logMe(handle,1,"f_Mode_Entry : "+f_Mode_Entry,debugMode);
   logMe(handle,1,"f_Period : "+f_Period,debugMode);
   logMe(handle,1,"f_Mode_BL : "+f_Mode_BL,debugMode);
   logMe(handle,1,"f_Input_BaseLine : "+f_Input_BaseLine,debugMode);
   logMe(handle,1,"f_Check_Distance_BL : "+f_Check_Distance_BL,debugMode);
   logMe(handle,1,"f_Check_Cross_BL : "+f_Check_Cross_BL,debugMode);
   logMe(handle,1,"f_Input_Conf_1 : "+f_Input_Conf_1,debugMode);
   logMe(handle,1,"f_Input_Conf_2 : "+f_Input_Conf_2,debugMode);
   logMe(handle,1,"f_Input_Volatility : "+f_Input_Volatility,debugMode);
   logMe(handle,1,"f_Input_Exit_1 : "+f_Input_Exit_1,debugMode);
   logMe(handle,1,"f_Input_Exit_2 : "+f_Input_Exit_2,debugMode);
   logMe(handle,1,"f_Mode_SL : "+f_Mode_SL,debugMode);
   logMe(handle,1,"f_Nb_Cand_SL : "+f_Nb_Cand_SL,debugMode);
   logMe(handle,1,"f_Coef_ATR_SL : "+f_Coef_ATR_SL,debugMode);
   logMe(handle,1,"f_Coef_ATR_SL_Min : "+f_Coef_ATR_SL_Min,debugMode);
   logMe(handle,1,"f_Risque_Max_Val : "+f_Risque_Max_Val,debugMode);
   logMe(handle,1,"f_Risque_Pct : "+f_Risque_Pct,debugMode);
   logMe(handle,1,"f_Mode_Trailing : "+f_Mode_Trailing,debugMode);
   logMe(handle,1,"f_Coef_ATR_Trailing : "+f_Coef_ATR_Trailing,debugMode);
   logMe(handle,1,"f_PourCent_Close : "+f_PourCent_Close,debugMode);
   logMe(handle,1,"f_PourCent_Pyram : "+f_PourCent_Pyram,debugMode);
   logMe(handle,1,"f_Spread_Limit : "+f_Spread_Limit,debugMode);
   logMe(handle,1,"f_Debug_Mode : "+f_Debug_Mode,debugMode);
   logMe(handle,1,"f_Prefixe_Magic : "+f_Prefixe_Magic,debugMode);
   logMe(handle,1,"f_MovingTP : "+f_MovingTP,debugMode);
   logMe(handle,1,"f_BaseTP : "+f_BaseTP,debugMode);
   logMe(handle,1,"f_Strat_GoalTP : "+f_Strat_GoalTP,debugMode);
   logMe(handle,1,"f_isBackTest : "+f_isBackTest,debugMode);
   logMe(handle,1,"f_ModeClose : "+f_ModeClose,debugMode);
   logMe(handle,1,"f_useStack : "+f_useStack,debugMode);
   logMe(handle,1,"f_Input_Stack_1 : "+f_Input_Stack_1,debugMode);
   logMe(handle,1,"f_Continuation : "+f_Continuation,debugMode);
   logMe(handle,1,"f_Direction_filter : "+f_Direction_filter,debugMode);

   return 1;

  }

//+------------------------------------------------------------------+
