//+------------------------------------------------------------------+
//|                              Calculate phases with BB            |
//| Based on an indicator from Gousset / Vitale                      |
//| modified by B. DURAND                                            |
//| extralight version for no surfer candles                         |
//| and less indicators on the graph                                 |
//+------------------------------------------------------------------+
#property copyright "G. GOUSSET  N. VITALE B.DURAND"
#property version   "1.00"
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_color1 Red // BB  sup  
#property indicator_color2 Green // BB inf  
#property indicator_color3 LightSeaGreen // MA


//---- indicator parameters
extern int Periode = 20; // MA
extern double EType_Band = 2.0;  //Std
extern int SeuilPhase1 = 15;  //threshold of volatility for phase 1
extern int PourCent_ToleranceBBPhase1 = 5; // % tolerance for BB move during phase 1
extern int PourCent_RatioET_TR_Phase1 = 150; // % ration Std / TR for phase 1

//---- buffers
double MovingBuffer[]; // MA
double UpperBuffer[]; // BB sup
double LowerBuffer[]; // BB inf

double EType[] ; // Std Dev
double ExtVolDerBuffer[];// Volatility
double Phase[]; // the phase (1,2,3,4)
double Sens[]; // direction of the trend
//+------------------------------------------------------------------+
//| initialisation |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---- indicators
   IndicatorDigits(Digits);
   IndicatorBuffers(7);

   SetIndexStyle(0,DRAW_LINE,0,2);
   SetIndexBuffer(0,UpperBuffer); // BB sup
   SetIndexLabel(0,"BB Sup red");

   SetIndexStyle(1,DRAW_LINE,0,2);
   SetIndexBuffer(1,LowerBuffer); // BB inf
   SetIndexLabel(1,"BB inf green");

   SetIndexStyle(2,DRAW_LINE,0,1);
   SetIndexBuffer(2,MovingBuffer); // MA
   SetIndexLabel(2,"MA "+Periode);

   SetIndexStyle(3,DRAW_NONE,0,2);
   SetIndexBuffer(3,EType);
   SetIndexLabel(3,"Std Dev");

   SetIndexStyle(4,DRAW_NONE,0,2);
   SetIndexBuffer(4,ExtVolDerBuffer);
   SetIndexLabel(4,"Volatility");

   SetIndexStyle(5,DRAW_NONE,0,2);
   SetIndexBuffer(5,Phase);
   SetIndexLabel(5,"Phase");

   SetIndexStyle(6,DRAW_NONE,0,2);
   SetIndexBuffer(6,Sens);
   SetIndexLabel(6,"Direction");

   SetIndexDrawBegin(0,Periode);

//----
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,pos,high_index,low_index ;
   double tr=0.0;

   int limit=Bars-Periode;

   if(rates_total<=Periode)
     {
      return(0);
     }

   ArraySetAsSeries(MovingBuffer,false);
   ArraySetAsSeries(UpperBuffer,false);
   ArraySetAsSeries(LowerBuffer,false);
   ArraySetAsSeries(EType,false);
   ArraySetAsSeries(ExtVolDerBuffer,false);
   ArraySetAsSeries(Phase,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(open,false);
   ArraySetAsSeries(time,false);
   ArraySetAsSeries(Sens,false);

//--- initial zero
   if(prev_calculated<1)
     {
      for(i=0; i<Periode; i++)
        {
         MovingBuffer[i]=EMPTY_VALUE;
         UpperBuffer[i]=EMPTY_VALUE;
         LowerBuffer[i]=EMPTY_VALUE;
         EType[i]=EMPTY_VALUE;
         ExtVolDerBuffer[i]=EMPTY_VALUE;
         Phase[i]=0.0;
         Sens[i]=0.0;
        }

     }

   if(prev_calculated>Periode)
     {
      pos=prev_calculated;
     }
   else
     {
      pos=Periode;
     }

   for(i=pos; i<rates_total; i++)
     {

      //--- middle line
      MovingBuffer[i]=SimpleMA(i,Periode,close);
      //--- calculate and write down StdDev
      EType[i]=StdDev_Func(i,close,MovingBuffer,Periode);

      UpperBuffer[i] = MovingBuffer[i] + EType[i] * EType_Band ; // BB sup

      LowerBuffer[i] = MovingBuffer[i] - EType[i] * EType_Band ; // BB inf

      //+------------------------------------------------------------------+
      //| Calculate volatility and phases                                  |
      //+------------------------------------------------------------------+
      high_index=ArrayMaximum(EType,Periode,i-Periode+1);
      low_index=ArrayMinimum(EType,Periode,i-Periode+1);
      tr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);

      if(i > Periode)
        {
         ExtVolDerBuffer[i] = (EType[i] - EType[high_index]) / (EType[high_index] - EType[low_index]);
         ExtVolDerBuffer[i]=(ExtVolDerBuffer[i]+1.0)*100.0;// indic between 0 and 100
        }

      //check Phase 1 : if BB are flat or they are tightening and low volatility
      if(UpperBuffer[i-1]>=UpperBuffer[i] && LowerBuffer[i-1]<=LowerBuffer[i]
         && ExtVolDerBuffer[i]>=0.0 && ExtVolDerBuffer[i]<=SeuilPhase1 && tr>(EType[i]*(PourCent_RatioET_TR_Phase1/100.0))
         && (EType[i]<=(EType[i-1]*(1+(PourCent_ToleranceBBPhase1/100.00))))
         && (Phase[i-1]==1.0 || Phase[i-1]==4.0 || Phase[i-1]==0 || Phase[i-1]==EMPTY_VALUE)) 
        {
         Phase[i]=1.0;
         Sens[i]=Sens[i-1];
        }
      else
        {
         // check phase  2 : if BB are expanding
         if(((UpperBuffer[i-1]<UpperBuffer[i])
             && (LowerBuffer[i-1]>LowerBuffer[i]))
            && (EType[i]>(EType[i-1]*(1+(PourCent_ToleranceBBPhase1/100.00))))
           )
           {
            Phase[i]=2.0;
            if(MathAbs(close[i]-UpperBuffer[i])<MathAbs(close[i]-LowerBuffer[i]))
              {//if the price is closer to BB sup then direction is long
               Sens[i]=1.0;
              }
            else
              {
               Sens[i]=-1.0;
              }
           }
         else
           {
            // check phase 3 : if BB are in the same direction and it was a phase 2 or 3 
            // if it was a phase 4, check
            if((((UpperBuffer[i-1]<=UpperBuffer[i] && LowerBuffer[i-1]<=LowerBuffer[i] && Sens[i-1]==1.0)
                 ||(UpperBuffer[i-1]>=UpperBuffer[i] && LowerBuffer[i-1]>=LowerBuffer[i] && Sens[i-1]==-1.0))
                && (Phase[i-1]==2.0 || Phase[i-1]==3.0))
               || ((((UpperBuffer[i-1]<=UpperBuffer[i] && LowerBuffer[i-1]<=LowerBuffer[i] && Sens[i-1]==1.0)
                     ||(UpperBuffer[i-1]>=UpperBuffer[i] && LowerBuffer[i-1]>=LowerBuffer[i] && Sens[i-1]==-1.0)))
                   && Phase[i-1]==4.0 && (EType[i]>(EType[i-1]))))
              {
               Phase[i]=3.0;
               if(MathAbs(close[i]-UpperBuffer[i])<MathAbs(close[i]-LowerBuffer[i]))
                 {//if the price is closer to BB sup then direction is long
                  Sens[i]=1.0;
                 }
               else
                 {
                  Sens[i]=-1.0;
                 }
              }
            else
              {
               //check phase 4 : // if BB are flat and are tightening after phase 3 and still high volatility
               if(((UpperBuffer[i-1]>UpperBuffer[i] && Sens[i-1]==1.0) || (LowerBuffer[i-1]<LowerBuffer[i] && Sens[i-1]==-1.0))
                  && tr<(EType[i]*(PourCent_RatioET_TR_Phase1/100.0))
                  && (Phase[i-1]==3.0 || Phase[i-1]==4.0))
                 {
                  Phase[i]=4.0;
                  Sens[i]=Sens[i-1];
                 }
               else  // if indeterminated
                 {
                  // if low volatility = phase 1
                  if(ExtVolDerBuffer[i]>=0.0 && ExtVolDerBuffer[i]<=SeuilPhase1 && tr>(EType[i]*(PourCent_RatioET_TR_Phase1/100.0)))
                    {
                     Phase[i]=1.0;
                     Sens[i]=Sens[i-1];
                    }
                  else
                    {
                     // if violent reversal, walculate the direction and phase
                     if(MathAbs(close[i]-UpperBuffer[i])<MathAbs(close[i]-LowerBuffer[i]))
                       {//if the price is closer to BB sup then direction is long
                        Sens[i]=1.0;
                       }
                     else
                       {
                        Sens[i]=-1.0;
                       }
                     if(Sens[i]!=Sens[i-1])
                       {
                        // if BB are expanding phase 2 else if previous phase is 4 we keep the direction
                        if(EType[i]>(EType[i-1]*(1+(PourCent_ToleranceBBPhase1/100.00))))
                          {
                           Phase[i]=2.0;
                          }
                        else
                          {
                           Phase[i]=Phase[i-1];
                           if(Phase[i-1]==4.0)
                             {
                              Sens[i]=Sens[i-1];
                             }
                          }
                       }
                     else
                       {
                        //keep previous phase
                        Phase[i]=Phase[i-1];
                        if(Phase[i-1]==4.0)
                          {
                           Sens[i]=Sens[i-1];
                          }
                       }
                    }
                 }
              }

           }
        }
     } // end loop index

//----
   return(rates_total-1);
  }


//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position>=period)
     {
      //--- calcualte StdDev
      for(int i=0; i<period; i++)
         StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
      StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
     }
//--- return calculated value
   return(StdDev_dTmp);
  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
