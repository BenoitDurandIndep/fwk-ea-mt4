//+------------------------------------------------------------------+
//|                                              MoneyManagement.mqh |
//|                                                    Benoit Durand |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property link      "http://www.mql4.com"
#property strict
//+------------------------------------------------------------------+
//| include                                                          |
//+------------------------------------------------------------------+
#include <FileManagement.mqh>
#include <OrderObject.mqh>

//+------------------------------------------------------------------+
//| list of functions                                                |
//+------------------------------------------------------------------+
//| TrailingStopTicket : manages trailing stop for an input ticket   |
//| TrailingStopTicketRessert : manages trailing stop for an input ticket 
//| ModifySL : updates the SL and TP of a ticket                     |
//| SplitOrderStrat : returns the size                               |
//| ModifySize : close partially an ticket                           |
//| DecreasePosition : close partially an position                   |
//| DecreasePosition : close 50% an position                         |
//| ATRinPips : returns ATR in pips                                  |
//| ATRinPoints : returns ATR in points                              |
//| CalculateVol : returns size of a position according to the SL    |
//| CalculateRisk : returns the risk in % for an input amount        |
//| TickValuePerBar : returns calculated tick value                  |
//| returns size of the order from a risk % and a SL                 |
//| getFixeTP : returns the TP value function of the direction       |
//| getProfitPossible : returns therical profitability               |
//| getLossPossible : returns therical profitability                 |
//| direction : 1 for BUY, -1 for SELL                               |
//| updateRisk : updates risk indicators en the array                |
//| checkOrderCurrency : check the global risk on theses currencies  |
//| checkOrderIndexList : check the global risk on an index          | 
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| TrailingStopTicket : manages trailing stop for an input ticket   |
//| hmonstop=delta between the entry and and SL                      |
//| hmonTrailing=distance if we move the SL of this same distance    |
//| return 1 if ok -1 if error                                       |
//+------------------------------------------------------------------+
int TrailingStopTicket(const int hticket,const double hmonTrailing, const double hmonStop,
                       const int hHandle=0,const int hdebugMode=0, const bool movingTP=true,const bool showTrail=false,const int h_log=0)
  {
   double seuilStop,risque=hmonStop,trailing=hmonTrailing,TP,etatRisque[4];
   int resModify=0;


   if(OrderSelect(hticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      //pourl'ordre
      TP=OrderTakeProfit();


      if(OrderType()==OP_BUY )
        {
         seuilStop=NormalizeDouble(Bid-hmonStop*Point,5);//Seuil=SL+trailing

         if(showTrail)
           {
            logMe(hHandle,2,"TrailingStopHourInfo trailing:"+DoubleToStr(trailing,0)+" futur SL size :"+DoubleToStr(hmonStop,0)+" futur SL :"+seuilStop+" (Bid-OrderStopLoss())>(trailing+SL)*Point =>("+Bid+"-"+OrderStopLoss()+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
           }

         if(OrderStopLoss()<seuilStop && (Bid-OrderStopLoss())>(trailing+hmonStop)*Point)
           {
            if(!showTrail)
              {
               logMe(hHandle,2,"TrailingStopHourInfo trailing:"+DoubleToStr(trailing,0)+" futur SL size :"+DoubleToStr(hmonStop,0)+" futur SL :"+seuilStop+" (Bid-OrderStopLoss())>(trailing+SL)*Point =>("+Bid+"-"+OrderStopLoss()+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
              }
            logMe(hHandle,1,"TrailingStopTicket : Entry hmonTrailing="+DoubleToStr(hmonTrailing,0)+" hmonStop="+DoubleToStr(hmonStop,0),hdebugMode);
            logMe(hHandle,1,"TrailingStopTicket : Order update "+hticket+" Bid "+Bid+" SL "+seuilStop,hdebugMode);

            if(movingTP)
              {
               TP+=trailing*Point;
               logMe(hHandle,1,"TrailingStopTicket OK old TP :"+OrderTakeProfit()+" new TP "+TP,hdebugMode);
              }

            resModify=ModifySL(hticket,seuilStop, TP,50.0,h_log,hHandle,hdebugMode);
            if(resModify==1)
              {
               logMe(hHandle,1,"TrailingStopTicket : order updated.",hdebugMode);
              }
            if(resModify==-1)
              {
               logMe(hHandle,9,"TrailingStopTicket : ERROR WHILE UPDATING",hdebugMode);
              }
            if(resModify==0)
              {
               logMe(hHandle,5,"TrailingStopTicket : no update",hdebugMode);
              }

           }
        }
      else
         if(OrderType()==OP_SELL )
           {
            seuilStop=NormalizeDouble(Ask+trailing*Point,5);

            if(showTrail)
              {
               logMe(hHandle,2,"TrailingStopHourInfo trailing:"+DoubleToStr(trailing,0)+" futur SL size :"+DoubleToStr(hmonStop,0)+" futur SL:"+seuilStop+" (OrderStopLoss()-Ask)>(trailing+SL)*Point =>("+OrderStopLoss()+"-"+Ask+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
              }
            // if actual SL > futur SL and if delta SL-Ask > trailing+actual delta 
            if(OrderStopLoss()>seuilStop && (OrderStopLoss()-Ask)>(trailing+hmonStop)*Point)
              {
               logMe(hHandle,1,"TrailingStopTicket : Entry hmonTrailing="+DoubleToStr(hmonTrailing,0)+" hmonStop="+DoubleToStr(hmonStop,0),hdebugMode);
               logMe(hHandle,1,"TrailingStopTicket : Order update "+hticket+" Ask "+Ask+" SL "+seuilStop,hdebugMode);

               if(movingTP)
                 {
                  TP-=trailing*Point;
                  logMe(hHandle,1,"TrailingStopTicket OK old TP :"+OrderTakeProfit()+" nouveau TP "+TP,hdebugMode);
                 }
               resModify=ModifySL(hticket,seuilStop, TP,50.0,h_log,hHandle,hdebugMode);
               if(resModify==1)
                 {
                  logMe(hHandle,1,"TrailingStopTicket : Order updated.",hdebugMode);
                 }
               if(resModify==-1)
                 {
                  logMe(hHandle,9,"TrailingStopTicket : ERROR WHILE UPDATING THE ORDER.",hdebugMode);
                 }
               if(resModify==0)
                 {
                  logMe(hHandle,5,"TrailingStopTicket : no update.",hdebugMode);
                 }

              }
           }
     }
   return(1);
  }

//+------------------------------------------------------------------+
//| TrailingStopTicketRessert : manages trailing stop for an input ticket     
//| tighten trail after progression                                  |
//| hmonstop=delta between the entry and and SL                      |
//| hmonTrailing=distance if we move the SL of this same distance    |
//| hcoefRessert=SL coef from we use hmonNewTrailing instead of hmonTrailing
//| return 1 if ok -1 if error                                       |
//+------------------------------------------------------------------+
int TrailingStopTicketRessert(const int hticket,const double hmonTrailing, const double hmonStop,const double hcoefRessert,const double hmonNewTrailing,
                              const int hHandle=0,const int hdebugMode=0, const bool movingTP=true,const bool showTrail=false,const int h_log=0)
  {
   double seuilStop,risque=hmonStop,trailing=hmonTrailing,TP,etatRisque[4];
   bool showTrace=false;
   int resModify=0;

   if(OrderSelect(hticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      TP=OrderTakeProfit();

      if(OrderType()==OP_BUY)
        {
         //determine if new trailing instead of initial one
         if(hmonStop>0 && (Bid-OrderOpenPrice())>(hmonStop*hcoefRessert))
           {
            trailing=hmonNewTrailing;
            showTrace=true;
           }

         seuilStop=NormalizeDouble(OrderStopLoss()+hmonStop*Point,5);//Seuil=SL+trailing

         if(showTrail)
           {
            logMe(hHandle,2,"TrailingStopHourInfo trailing:"+DoubleToStr(trailing,0)+" futur SL size :"+DoubleToStr(hmonStop,0)+" futur SL :"+seuilStop+" (Bid-OrderStopLoss())>(trailing+SL)*Point =>("+Bid+"-"+OrderStopLoss()+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
           }

         if(OrderStopLoss()<seuilStop && (Bid-OrderStopLoss())>(trailing+hmonStop)*Point)
           {
            logMe(hHandle,1,"TrailingStopTicket : Entry hmonTrailing="+DoubleToStr(hmonTrailing,0)+" hmonStop="+DoubleToStr(hmonStop,0)+" hcoefRessert="+DoubleToStr(hcoefRessert,0)+" hmonNewTrailing="+DoubleToStr(hmonNewTrailing,0),hdebugMode);
            if(trailing==hmonNewTrailing)
              {
               if(showTrace)
                 {
                  logMe(hHandle,3,"TrailingStopTicket : tighten SL ! (Bid-OrderOpenPrice())>(hmonStop*hcoefRessert) =>("+Bid+"-"+OrderOpenPrice()+")>(+"+DoubleToStr(hmonStop,0)+"*"+DoubleToStr(hcoefRessert,0)+")",hdebugMode);
                 }

               logMe(hHandle,3,"TrailingStopTicket : New Trailing (Bid-OrderStopLoss())>(trailing+SL)*Point =>("+Bid+"-"+OrderStopLoss()+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
              }
            logMe(hHandle,1,"TrailingStopTicket : Order update "+hticket+" Bid "+Bid+" SL "+seuilStop,hdebugMode);

            if(movingTP)
              {
               TP+=trailing*Point;
               logMe(hHandle,1,"TrailingStopTicket OK old TP :"+OrderTakeProfit()+" nouveau TP "+TP,hdebugMode);
              }

            resModify=ModifySL(hticket,seuilStop, TP,50.0,h_log,hHandle,hdebugMode);
            if(resModify==1)
              {
               logMe(hHandle,1,"TrailingStopTicket : Order updated.",hdebugMode);
              }
            if(resModify==-1)
              {
               logMe(hHandle,9,"TrailingStopTicket : ERROR UPDATING THE ORDER.",hdebugMode);
              }
            if(resModify==0)
              {
               logMe(hHandle,5,"TrailingStopTicket : no update.",hdebugMode);
              }
           }
        }
      else
         if(OrderType()==OP_SELL)
           {
            //determine if new trailing instead of initial one
            if(risque>0 && (OrderOpenPrice()-Ask)>(hmonStop*hcoefRessert))
              {
               trailing=hmonNewTrailing;
               showTrace=true;
              }
            seuilStop=NormalizeDouble(OrderStopLoss()-trailing*Point,5);

            if(showTrail)
              {
               logMe(hHandle,2,"TrailingStopHourInfo trailing:"+DoubleToStr(trailing,0)+" futur SL size:"+DoubleToStr(hmonStop,0)+" futur SL:"+seuilStop+" (OrderStopLoss()-Ask)>(trailing+SL)*Point =>("+OrderStopLoss()+"-"+Ask+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
              }
            // if actual SL > futur SL and if delta SL-Ask > trailing+actual delta 
            if(OrderStopLoss()>seuilStop && (OrderStopLoss()-Ask)>(trailing+hmonStop)*Point)
              {
               logMe(hHandle,1,"TrailingStopTicket : Entry hmonTrailing="+DoubleToStr(hmonTrailing,0)+" hmonStop="+DoubleToStr(hmonStop,0)+" hcoefRessert="+hcoefRessert+" hmonNewTrailing="+DoubleToStr(hmonNewTrailing,0),hdebugMode);
               if(trailing==hmonNewTrailing)
                 {
                  if(showTrace)
                    {
                     logMe(hHandle,3,"TrailingStopTicket : tighten SL ! (OrderOpenPrice()-Ask)>(hmonStop*hcoefRessert) =>("+OrderStopLoss()+"-"+Ask+")>(+"+DoubleToStr(hmonStop,0)+"*"+hcoefRessert+")",hdebugMode);
                    }
                  logMe(hHandle,3,"TrailingStopTicket : If move Trailing (OrderStopLoss()-Ask)>(trailing+SL)*Point =>("+OrderStopLoss()+"-"+Ask+")>("+DoubleToStr(trailing,0)+"+"+DoubleToStr(hmonStop,0)+")*"+Point,hdebugMode);
                 }
               logMe(hHandle,1,"TrailingStopTicket : Order update "+hticket+" Ask "+Ask+" SL "+seuilStop,hdebugMode);

               if(movingTP)
                 {
                  TP-=trailing*Point;
                  logMe(hHandle,1,"TrailingStopTicket OK old TP :"+OrderTakeProfit()+" nouveau TP "+TP,hdebugMode);
                 }
               resModify=ModifySL(hticket,seuilStop, TP,50.0,h_log,hHandle,hdebugMode);
               if(resModify==1)
                 {
                  logMe(hHandle,1,"TrailingStopTicket : Order updated.",hdebugMode);
                 }
               if(resModify==-1)
                 {
                  logMe(hHandle,9,"TrailingStopTicket : ERROR UPDATING ORDER.",hdebugMode);
                 }
               if(resModify==0)
                 {
                  logMe(hHandle,5,"TrailingStopTicket : no update.",hdebugMode);
                 }
              }
           }
     }
   return(1);
  }

//+------------------------------------------------------------------+
//| ModifySL : updates the SL and TP of a ticket                     |
//| hticket : the ticket                                             |
//| hmonSeuilStop : new SL value(ex 1.12452)                         |
//| hMonTP : new TP value (ex 1.13654)                               |
//| hOrder : handle of order file                                    |
//| hLog : handle of log file                                        |
//| returns 1 if ok -1 if error                                      |
//+------------------------------------------------------------------+
int ModifySL(const int hticket,const double hmonSeuilStop, const double hMonTP=0.0,const double hMargePolution=50.0,const int hOrder=0,const int hLog=0,const int hdebugMode=0)
  {
   if(OrderSelect(hticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      double TP=OrderTakeProfit(), oldSL=OrderStopLoss(),etatRisque[4];
      double newTP=hMonTP;
      double newSL=hmonSeuilStop;
      if(newTP==0.0)
        {
         newTP=TP;
        }
      if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
        {
         if(newSL>oldSL+(hMargePolution*Point))
           {
            if(OrderModifyPreChecked(OrderType(),OrderStopLoss(),TP,OrderOpenPrice(),
                                     OrderExpiration(),hticket,OrderOpenPrice(),newSL,newTP,0,White))
              {
               if(!OrderModify(hticket,OrderOpenPrice(),newSL,newTP,0,White))
                 {
                  logMe(hLog,9,"ERROR TrailingStopTicket : OrderTrailing error "+Fun_Error(GetLastError()),hdebugMode);
                  return(-1);
                 }
               else
                 {
                  updateRisk(hticket,etatRisque);
                  writeOrderlog(hOrder,hdebugMode,OrderTicket(), "BUY",Symbol(),OrderMagicNumber(),Bid,OrderOpenPrice(),newSL,newTP,etatRisque[2],etatRisque[3],OrderLots(),MarketInfo(Symbol(),MODE_SPREAD)," MODIFY BUY", hLog);
                  return(1);
                 }
              }
           }
        }

      if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP)
        {
         if(newSL<oldSL-(hMargePolution*Point))
           {
            if(OrderModifyPreChecked(OrderType(),OrderStopLoss(),TP,OrderOpenPrice(),
                                     OrderExpiration(),hticket,OrderOpenPrice(),newSL,newTP,0,White))
              {
               if(!OrderModify(hticket,OrderOpenPrice(),newSL,newTP,0,White))
                 {
                  logMe(hLog,9,"ERROR TrailingStopTicket : OrderTrailing error "+Fun_Error(GetLastError()),hdebugMode);
                  return(-1);
                 }
               else
                 {
                  updateRisk(hticket,etatRisque);
                  writeOrderlog(hOrder,hdebugMode,OrderTicket(), "SELL",Symbol(),OrderMagicNumber(),Ask,OrderOpenPrice(),newSL,newTP,etatRisque[2],etatRisque[3],OrderLots(),MarketInfo(Symbol(),MODE_SPREAD)," MODIFY SELL", hLog);
                  return(1);
                 }
              }
           }
        }
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| SplitOrderStrat : returns the size                               |
//| hBaseLot : base size to split                                    |
//| hWishSize : % of the size wanted                                 |
//+------------------------------------------------------------------+
double SplitOrderStrat(const double hBaseLot,const int hWishSize,const int hCommentLog=0,const int hDebugMode=0)
  {
   double resLot=0.0;
   int digits=2;

   logMe(hCommentLog,1,"SplitOrderStart hBaseLot="+hBaseLot+" hWishSize="+hWishSize,hDebugMode);
   if(hBaseLot>0.0 && hWishSize>0)
     {
      if(MarketInfo(Symbol(),MODE_LOTSTEP)!=0.01)
        {
         digits=1;
        }

      resLot=NormalizeDouble(hBaseLot*(hWishSize/100.0),digits);
     }
   else
     {
      logMe(hCommentLog,9,"SplitOrderStart ERROR hBaseLot="+hBaseLot+" hWishSize="+hWishSize,hDebugMode);
     }

   return resLot;
  }

//+------------------------------------------------------------------+
//| ModifySize : close partially an ticket                           |
//| hticket : the ticket                                             |
//| hMaTaille : new size(ex 0.5)                                     |
//| hOrderLog : handle of order file                                 |
//| hCommentLog : handle of log file                                 |
//| returns 1 if ok -1 if error                                      |
//+------------------------------------------------------------------+
int ModifySize(const int hticket,const double hMaTaille, const int hOrderLog=0,const int hCommentLog=0,const int hDebugMode=0)
  {
   if(hMaTaille>0.0 && OrderSelect(hticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      //pourl'ordre
      double etatRisque[4];
      logMe(hCommentLog,1,"Close partially "+hticket+" : from "+OrderLots()+" to "+(OrderLots()-hMaTaille),hDebugMode);
      RefreshRates();

      //ORDER CLOSE NO PRECHECK !!!
      if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
        {

         if(!OrderClose(hticket,hMaTaille,Bid,20,Red))
           {
            logMe(hCommentLog,9,"ERROR partial close "+hticket+" : Error "+Fun_Error(GetLastError()),hDebugMode);
            return(-1);
           }
         else
           {
            updateRisk(hticket,etatRisque);
            writeOrderlog(hOrderLog,hDebugMode,OrderTicket(), "BUY",Symbol(),OrderMagicNumber(),Bid,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit(),etatRisque[2],etatRisque[3],OrderLots(),MarketInfo(Symbol(),MODE_SPREAD)," PARTIAL CLOSE BUY", hCommentLog);
            return(1);
           }
        }

      if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP)
        {

         if(!OrderClose(hticket,hMaTaille,Ask,20,Red))
           {
            logMe(hCommentLog,9,"ERROR partial close "+hticket+" : Error "+Fun_Error(GetLastError()),hDebugMode);
            return(-1);
           }
         else
           {
            updateRisk(hticket,etatRisque);
            writeOrderlog(hOrderLog,hDebugMode,OrderTicket(), "SELL",Symbol(),OrderMagicNumber(),Ask,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit(),etatRisque[2],etatRisque[3],OrderLots(),MarketInfo(Symbol(),MODE_SPREAD)," PARTIAL CLOSE SELL", hCommentLog);
            return(1);
           }

        }
      RefreshRates();
     }
   return(0);
  }


//+------------------------------------------------------------------+
//| DecreasePosition : close partially an position                   |
//| hMyBook : the orderbook object                                   |
//| hRemovedLot : size to remove                                     |
//| hOrderLog : handle of order file                                 |
//| hCommentLog : handle of log file                                 |
//| returns the number of updated tickets                            |
//+------------------------------------------------------------------+
int DecreasePosition(OrderSelection &hMyBook, const double hRemovedLot=0.0, const int hOrderLog=0,const int hCommentLog=0,const int hDebugMode=0)
  {
   double nbLotsOpen=hMyBook.TotalPosition();
   double nbLotsAFermer=hRemovedLot;
   double nbLotsEnCours=0.0;
   int nbtickets=hMyBook.Count();
   int i=nbtickets-1; // counter
   int nbOrdresModified=0;

   while(i>=0 && nbLotsAFermer>0.0)// loop on array while there is still positions to close
     {
      Order* temp = hMyBook.Get(i);
      nbLotsEnCours=temp.lots;

      if(nbLotsEnCours>nbLotsAFermer) // partial close
        {

         if(ModifySize(temp.ticket,nbLotsAFermer, hOrderLog,hCommentLog,hDebugMode)<=0)
           {
            Sleep(1000);
            if(ModifySize(temp.ticket,nbLotsAFermer, hOrderLog,hCommentLog,hDebugMode)<=0)//2nd try
              {
               logMe(hCommentLog,9,"ERROR DecreasePosition  : ticket "+temp.ticket,hDebugMode);
              }
            else
              {
               nbLotsAFermer=0;
               nbOrdresModified++;
              }
           }
         else
           {
            nbLotsAFermer=0.0;
            nbOrdresModified++;
           }
        }
      else  // full close
        {
         if(ModifySize(temp.ticket,nbLotsEnCours, hOrderLog,hCommentLog,hDebugMode)<=0)
           {
            Sleep(1000);
            if(ModifySize(temp.ticket,nbLotsEnCours, hOrderLog,hCommentLog,hDebugMode)<=0)//2nd try
              {
               logMe(hCommentLog,9,"ERROR DecreasePosition  : ticket "+temp.ticket,hDebugMode);
              }
            else
              {
               nbLotsAFermer-=nbLotsEnCours;
               nbOrdresModified++;
              }
           }
         else
           {
            nbLotsAFermer-=nbLotsEnCours;
            nbOrdresModified++;
           }
        }
      i--;
     }
   return nbOrdresModified;
  }

//+------------------------------------------------------------------+
//| DecreasePosition : close 50% an position                         |
//| hMyBook : the orderbook object                                   |
//| hOrderLog : handle of order file                                 |
//| hCommentLog : handle of log file                                 |
//| returns the number of updated tickets                            |
//+------------------------------------------------------------------+
int DecreaseHalfPosition(OrderSelection &hMyBook, const int hOrderLog=0,const int hCommentLog=0,const int hDebugMode=0)
  {
   double nbLotsOpen=hMyBook.TotalPosition();
   nbLotsOpen=NormalizeDouble(nbLotsOpen/2.0,2);
   if(nbLotsOpen>0.0)
     {
      return DecreasePosition(hMyBook, nbLotsOpen, hOrderLog,hCommentLog,hDebugMode);
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| ATRinPips : returns ATR in pips                                  |
//| if ATR is 10 pips returns 10                                     |
//+------------------------------------------------------------------+
double ATRinPips(const string hSymbol, const int hPeriod, const int hTimeFrame=0)
  {
   double ATR= iATR(hSymbol,hTimeFrame,hPeriod,1);

   Print("ATR ="+ATR+" symbol "+hSymbol+" hPeriod "+hPeriod+" hTimeFrame "+hTimeFrame);

   ATR=NormalizeDouble(ATR*(1/Point/10),5);

   return ATR;
  }

//+------------------------------------------------------------------+
//| ATRinPoints : returns ATR in points                              |
//| if ATR is 10 pips returns 100                                    |
//+------------------------------------------------------------------+
double ATRinPoints(const string hSymbol, const int hPeriod, const int hTimeFrame=0)
  {
   double ATR= iATR(hSymbol,hTimeFrame,hPeriod,1);

   Print("ATR ="+ATR+" symbol "+hSymbol+" hPeriod "+hPeriod+" hTimeFrame "+hTimeFrame);

   ATR=NormalizeDouble(ATR*(1/Point),5);

   return ATR;
  }


//+------------------------------------------------------------------+
//| CalculateVol : returns size of a position according to the SL    |
//| if risk is too high and pass margin call, cut the risk by 2 and then 4
//| hSens : BUY / SELL                                               |
//| hPercent : % of risk max                                         |
//| hStopLoss ; SL                                                   |
//+------------------------------------------------------------------+
double CalculateVol(const string hSens, const double hPercent,const  double hStopLoss, int handle)
  {
   double monLot=0.0,monCheck=0.0, monRisque=hPercent;
   int cmd;
   if(hSens=="BUY")
     {
      cmd=OP_BUY;
     }
   else
     {
      cmd=OP_SELL;
     }

   monLot=AccountPercentStopPips(monRisque,hStopLoss,handle);
   if(monLot>0.0)
     {

      monCheck=AccountFreeMarginCheck(Symbol(),cmd,monLot);

      if(monCheck<= AccountStopoutLevel() ||  monCheck<=0.0 || !MathIsValidNumber(monCheck))
        {
         monLot=AccountPercentStopPips(monRisque/2.0,hStopLoss,handle);
         if(monLot>0.0)
           {
            monCheck=AccountFreeMarginCheck(Symbol(),cmd,monLot);

            if(monCheck<= AccountStopoutLevel() ||  monCheck<=0.0 || !MathIsValidNumber(monCheck))
              {
               monLot=AccountPercentStopPips(monRisque/4.0,hStopLoss,handle);
               if(monLot>0.0)
                 {
                  monCheck=AccountFreeMarginCheck(Symbol(),cmd,monLot);

                  if(monCheck<= AccountStopoutLevel() ||  monCheck<=0.0 || !MathIsValidNumber(monCheck))
                    {
                     logMe(handle,1,"Risk is too high !! lot go to 0 : marginCall : "+AccountFreeMargin()+" - risk : "+monRisque/4.0+" - lot : "+monLot+" - check : "+monCheck+"",1);
                     monLot=0.0;
                    }
                 }
              }
           }
        }
     }
   return(monLot);
  }

//+------------------------------------------------------------------+
//| CalculateRisk : returns the risk in % for an input amount        |
//+------------------------------------------------------------------+
double CalculateRisk(double hValMax)
  {
   return hValMax*100.0/AccountEquity();//*100 pour le passer en %
  }

//+------------------------------------------------------------------+
//| TickValuePerBar : returns calculated tick value                  |
//+------------------------------------------------------------------+
double TickValuePerBar(string symbol, int shift=0)
  {

   string AC = AccountCurrency();
   string S1 = StringSubstr(symbol,0,3);
   string S2 = StringSubstr(symbol,3,3);

   if(AC==S2)
      return(1);

   double TS=MarketInfo(symbol,MODE_TICKSIZE);

   if(MarketInfo(symbol,MODE_DIGITS)==3)
      TS=MarketInfo(symbol,MODE_TICKSIZE)/100;

   if(AC==S1)
      return(MarketInfo(symbol,MODE_POINT) / iClose(symbol,PERIOD_M1,shift) / TS);

   GetLastError();

   string pair = StringConcatenate(AC,S2);

   if(MarketInfo(pair,MODE_DIGITS)==3)
      TS=MarketInfo(pair,MODE_TICKSIZE)/100;
   else
      TS=MarketInfo(pair,MODE_TICKSIZE);

   double rate = MarketInfo(pair,MODE_POINT) / iClose(pair,PERIOD_M1,shift) / TS;
   int    lerr = GetLastError();

   if(lerr!=0 && lerr!=ERR_HISTORY_WILL_UPDATED)
     {
      rate = 0;
     }

   return(rate);

  }

//+------------------------------------------------------------------+
//| returns size of the order from a risk % and a SL                 |
//| copied from http://www.autoforex.fr/plateforme-trading/metatrader4/programmation-mt4/calculer-la-taille-de-lots-en-fonction-du-risque/
//+------------------------------------------------------------------+
double AccountPercentStopPips(double percent, double stoploss, int handle)
  {
   double lot=0;
   double Point2pip = (MathPow(10, Digits % 2) * Point);
   double balance      = AccountEquity();
   double moneyrisk    = balance * percent / 100.0;
   double spread       = MarketInfo(Symbol(), MODE_SPREAD);
   double point        = MarketInfo(Symbol(), MODE_POINT);
   double ticksize     = MarketInfo(Symbol(), MODE_TICKSIZE);
   double tickvalue    = MarketInfo(Symbol(), MODE_TICKVALUE);
   double minlot =  MarketInfo(Symbol(),MODE_MINLOT);
   double maxlot =  MarketInfo(Symbol(),MODE_MAXLOT);
   int lotTrunc=0;
   int coeff=1;

   if(Digits==5 || Digits==3)
     {
      coeff=10;
     }
   logMe(handle,1,"tickvaluefix = tickvalue * (point*coeff)  / ticksize : ="+DoubleToStr(tickvalue,5)+" * ("+DoubleToStr(point,5)+"*"+DoubleToStr(coeff,5)+") / "+DoubleToStr(ticksize,5));
   double tickvaluefix = tickvalue * (point*coeff)  / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue

   logMe(handle,1,"lot=moneyrisk/(((MathAbs(stoploss)/Point2pip) + spread)*tickvaluefix) : "+moneyrisk+"/(((MathAbs("+DoubleToStr(stoploss,5)+")/"+Point2pip+")+"+spread+")*"+DoubleToStr(tickvaluefix,2),1);
   lot = moneyrisk/(((MathAbs(stoploss)/Point2pip) + spread)*tickvaluefix);
   //Ensure a correct lot size
   logMe(handle,1,"moneyrisk : "+moneyrisk+" - stoploss : "+DoubleToStr(stoploss,5)+" - spread : "+spread+" - lot : "+DoubleToStr(MathFloor(lot*100.0),2)+" - market minlot : "+minlot,1);

   if(minlot>0 && maxlot>0)
     {
      if(lot>maxlot)
        {
         lot = maxlot;
        }
      else
        {
         if(lot<minlot)
           {
            lot = 0.0;
           }
        }
     }
   lotTrunc=MathFloor(lot*100.0);
   return(NormalizeDouble(lotTrunc/100.0,2));
  }

//+------------------------------------------------------------------+
//| getFixeTP : returns the TP value function of the direction       |
//| sens : BUY / SELL                                                |
//| baseTP : added value in points ex 0.0050 for 50 pips             |
//+------------------------------------------------------------------+
double getFixeTP(const string sens,const double baseTP)
  {
   double p_nor=0.0;
   double TP=0.0;

   if(sens=="BUY")
     {
      p_nor=NormalizeDouble(Ask+baseTP,5);
      if(Ask<p_nor)
        {
         TP=p_nor;
        }
      else
        {
         TP=p_nor+baseTP*2.0;
        }
     }
   else
      if(sens=="SELL")
        {
         p_nor=NormalizeDouble(Bid-baseTP,5);
         if(Bid>p_nor)
           {
            TP=p_nor;
           }
         else
           {
            TP=p_nor-baseTP*2.0;
           }
        }
   return TP;
  }

//+------------------------------------------------------------------+
//| getProfitPossible : returns therical profitability               |
//| function of size, TP, entry                                      |
//+------------------------------------------------------------------+
double getProfitPossible(double nbLots, double TP, double open)
  {
   double Point2pip = (MathPow(10, Digits % 2) * Point);
   double tickvalue=MarketInfo(Symbol(),MODE_TICKVALUE) ;
   double ticksize     = MarketInfo(Symbol(), MODE_TICKSIZE);
   double spread       = MarketInfo(Symbol(), MODE_SPREAD);
   int coeff=1;
   if(Digits==5 || Digits==3)
     {
      coeff=10;
     }
   double tickvaluefix = tickvalue * (Point*coeff)  / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue

   return nbLots*((MathAbs(((TP-open))/Point2pip)-spread)*tickvaluefix); 
  }

//+------------------------------------------------------------------+
//| getLossPossible : returns therical profitability                 |
//| function of size, TP, entry                                      |
//| sens : 1 for BUY, -1 for SELL                                    |
//+------------------------------------------------------------------+
double getLossPossible(double nbLots, double SL, double open, int sens)
  {
   double Point2pip = (MathPow(10, Digits % 2) * Point);
   double tickvalue=MarketInfo(Symbol(),MODE_TICKVALUE) ;
   double ticksize     = MarketInfo(Symbol(), MODE_TICKSIZE);
   double spread       = MarketInfo(Symbol(), MODE_SPREAD);
   int coeff=1;
   if(Digits==5 || Digits==3)
     {
      coeff=10;
     }
   double tickvaluefix = tickvalue * (Point*coeff)  / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue

   if(sens>0)
     {
      if(SL>open)
        {
         return 0.0;
        }
     }
   else
     {
      if(SL<open)
        {
         return 0.0;
        }
     }
   return nbLots*(((MathAbs(((SL-open))/Point2pip)*-1)-spread)*tickvaluefix); 
  }


//+------------------------------------------------------------------+
//| direction : 1 for BUY, -1 for SELL                               |
//| _type : mql4 type of the order                                   |
//+------------------------------------------------------------------+
int direction(int _type)
  {
   if(_type < OP_BUY || _type > OP_SELLSTOP) // no valid order type
      return(0);
   if(_type % 2 > 0)
      return(-1);
   return(1);
  }

//+------------------------------------------------------------------+
//| updateRisk : updates risk indicators en the array                |
//| hticket : the ticket to analyse                                  |
//| tabRes : array with the ticket informations                      |
//| returns the array with updated data                              |
//+------------------------------------------------------------------+
void updateRisk(const int hticket,double &tabRes[])
  {

   if(OrderSelect(hticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      int orderType=OrderType();
      tabRes[0]=getProfitPossible(OrderLots(),OrderTakeProfit(),OrderOpenPrice()); // calcul du profit possible
      tabRes[1]=getLossPossible(OrderLots(),OrderStopLoss(),OrderOpenPrice(),direction(orderType));// calcul de la perte possible

      tabRes[2]=NormalizeDouble(-tabRes[1]/AccountEquity()*100,2);
      if(tabRes[1]<0)
        {
         tabRes[3]=NormalizeDouble(-tabRes[0]/tabRes[1],1);
        }
      else
        {
         tabRes[3]=0.0;
        }
     }
  }

//+------------------------------------------------------------------+
//| checkOrderCurrency : check the global risk on theses currencies  |
//| even positions from an other EA                                  |
//| curr : the currency pair                                         |
//| riskMax : max risk authorized                                    | 
//| maxCurr : max open poistions                                     |
//| returns the risk still authorized, 0 if max risk reached         |
//+------------------------------------------------------------------+
double checkOrderCurrency(const string curr,const double riskMax, int handle, const int maxCurr=99)
  {
   //split the pair
   string pairePrin=StringSubstr(curr,0,3);
   string paireSec=StringSubstr(curr,3,3);
   double riskTotal=0.0,lossTrade=0.0,riskOK=0.0;
   int nbCurr=0;

   for(int i = 0 ; i < OrdersTotal() ; i ++) 
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(StringFind(OrderSymbol(),pairePrin,0)>=0 || StringFind(OrderSymbol(),paireSec,0)>=0) // if the order contains one of the currencies
           {
            lossTrade=getLossPossible(OrderLots(),OrderStopLoss(),OrderOpenPrice(),direction(OrderType()));// possible loss 
            riskTotal+=CalculateRisk(lossTrade);// returns %
            nbCurr++;
           }
        }
     }

   riskOK=riskMax+riskTotal;
   if(riskOK<0.0)
     {
      riskOK=0.0;
     }
   if(nbCurr>=maxCurr)
     {
      riskOK=0.0;
     }

   logMe(handle,0,"Main pair :"+pairePrin+" Second pair:"+paireSec+" lossTrade:"+lossTrade+" riskTotal:"+riskTotal+" nbCurr:"+nbCurr,true);

   return riskOK;

  }

//+------------------------------------------------------------------+
//| checkOrderIndexList : check the global risk on an index          | 
//| even positions from an other EA                                  |
//| ind : the index                                                  |
//| riskMax : max risk authorized                                    | 
//| maxCurr : max open poistions                                     |
//| returns the risk still authorized, 0 if max risk reached         |
//+------------------------------------------------------------------+
double checkOrderIndexList(const string ind,const double riskMax, int handle, const int maxCurr=99)
  {
   double riskTotal=0.0,lossTrade=0.0,riskOK=0.0;
   int nbCurr=0;
   string fileList="list_index.txt"; // file containg index

   int hListIndex=openTXTReadFile(fileList);

   if(hListIndex!=INVALID_HANDLE)
     {
      string line="",listIndex="",resSplitLine[];
      bool exit=false;

      while(!FileIsEnding(hListIndex) && !exit)
        {
         line=FileReadString(hListIndex);
         StringSplit(line,StringGetCharacter("=",0),resSplitLine);
         listIndex=resSplitLine[1];
         if(StringFind(listIndex,ind,0)>=0)
           {
            exit=true;
            for(int i = 0 ; i < OrdersTotal() ; i ++)  
              {
               if(OrderSelect(i, SELECT_BY_POS))
                 {
                  if(StringFind(listIndex,OrderSymbol(),0)>=0) 
                    {
                     lossTrade=getLossPossible(OrderLots(),OrderStopLoss(),OrderOpenPrice(),direction(OrderType()));
                     riskTotal+=CalculateRisk(lossTrade);// returns a %
                     nbCurr++;
                    }
                 }
              }
           }
        }
      if(!exit)
        {
         logMe(handle,9,"ERROR Index :"+ind+" not found in file !!",true);
        }
     }
   else
     {
      logMe(handle,9,"ERROR File "+fileList+" not found !!",true);
     }

   riskOK=riskMax+riskTotal;
   if(riskOK<0.0)
     {
      riskOK=0.0;
     }
   if(nbCurr>=maxCurr)
     {
      riskOK=0.0;
     }

   logMe(handle,0,"index :"+ind+" lossTrade:"+lossTrade+" riskTotal:"+riskTotal+" nbCurr:"+nbCurr,true);

   return riskOK;

  }
//+------------------------------------------------------------------+
