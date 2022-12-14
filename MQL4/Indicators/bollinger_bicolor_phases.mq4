//+------------------------------------------------------------------+
//|                                     Bollinger Bands Bi-Color     |
//|                                 G. GOUSSET  N. VITALE            |
//|                                 B. DURAND                        |
//|         Used of Oncalculate and add phases                       |
//+------------------------------------------------------------------+
#property copyright "G. GOUSSET  N. VITALE B.DURAND"
#property version   "1.00"
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 12
#property indicator_color1 Red // BB sup going down
#property indicator_color2 Green // BB sup going up 
#property indicator_color3 LightSeaGreen // MA 
#property indicator_color4 Red // BB inf going down 
#property indicator_color5 Green // BB inf going up 
#property indicator_color6 Blue // MA phase 1


//---- indicator parameters
extern int Periode = 20;// MA
extern double EType_Band = 2.0;//Std
extern string ParamPhases = "++----------------------------++";
extern int SeuilPhase1 = 20;//threshold of volatility for phase 1
extern int ToleranceBBPhase1 = 20;// nb points tolerance for BB move during phase 1
extern int EcartMaxPhase1 = 3; // nb candles checked to determine if we are  after a phase 1
extern int LimiteAnalyse=200;//nb max cadles to analyze 

//---- buffers
double MovingBuffer[]; // MA
double UpperBuffer[]; // BB sup
double LowerBuffer[]; // BB inf

double UpperBGreen[] ; // BB sup going up
double UpperBRed[] ; // BB sup going down
double LowerBGreen[] ; // BB inf going up
double LowerBRed[] ; // BB inf going down
double MAPhase1[];//highlighting MA during phase 1
double EType[] ; // Std dev
double ExtVolSmoothBuffer[] ; // Volatility
double ExtVolDerBuffer[];
double Phase[]; // Phases
double BougieSurf[]; // count surfing candles

string baseObj="BBPhase_";

//+------------------------------------------------------------------+
//| initialisation |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---- indicators
   IndicatorDigits(Digits);
   IndicatorBuffers(13);

   SetIndexStyle(0,DRAW_LINE,0,2);
   SetIndexBuffer(0,UpperBRed);
   SetIndexLabel(0,"BB Sup Red");

   SetIndexStyle(1,DRAW_LINE,0,2);
   SetIndexBuffer(1,UpperBGreen);
   SetIndexLabel(1,"BB Sup Green");

   SetIndexStyle(2,DRAW_LINE,0,1);
   SetIndexBuffer(2,MovingBuffer);
   SetIndexLabel(2,"MA "+Periode);

   SetIndexStyle(3,DRAW_LINE,0,2);
   SetIndexBuffer(3,LowerBRed);
   SetIndexLabel(3,"BB Inf Red");

   SetIndexStyle(4,DRAW_LINE,0,2);
   SetIndexBuffer(4,LowerBGreen);
   SetIndexLabel(4,"BB Inf Green");

   SetIndexStyle(5,DRAW_LINE,0,5);
   SetIndexBuffer(5,MAPhase1);
   SetIndexLabel(5,"MA Phase 1");

   SetIndexStyle(6,DRAW_NONE,0,2);
   SetIndexBuffer(6,UpperBuffer);
   SetIndexLabel(6,"BB Sup");

   SetIndexStyle(7,DRAW_NONE,0,2);
   SetIndexBuffer(7,LowerBuffer);
   SetIndexLabel(7,"BB Inf");

   SetIndexStyle(8,DRAW_NONE,0,2);
   SetIndexBuffer(8,EType);
   SetIndexLabel(8,"Std Dev");

   SetIndexStyle(9,DRAW_NONE,0,2);
   SetIndexBuffer(9,ExtVolSmoothBuffer);
   SetIndexLabel(9,"Volatility");

   SetIndexStyle(10,DRAW_NONE,0,2);
   SetIndexBuffer(10,Phase);
   SetIndexLabel(10,"Phase");

   SetIndexStyle(11,DRAW_NONE,0,2);
   SetIndexBuffer(11,BougieSurf);
   SetIndexLabel(11,"Surfer");

   SetIndexBuffer(12,ExtVolDerBuffer);

   SetIndexDrawBegin(0,Periode);

//----
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   DeleteObjectsByString(baseObj, -1);
   DeleteObjectsByString(baseObj, -1);
   DeleteObjectsByString(baseObj, -1);

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
   int i,pos,high_index,low_index,j ;
   double atr=0.0;
   bool phase1Prec=false;

   int limit=Bars-Periode;

   if(rates_total<=Periode)
     {
      return(0);
     }

   ArraySetAsSeries(MovingBuffer,false);
   ArraySetAsSeries(UpperBuffer,false);
   ArraySetAsSeries(LowerBuffer,false);
   ArraySetAsSeries(UpperBGreen,false);
   ArraySetAsSeries(UpperBRed,false);
   ArraySetAsSeries(LowerBGreen,false);
   ArraySetAsSeries(LowerBRed,false);
   ArraySetAsSeries(MAPhase1,false);
   ArraySetAsSeries(EType,false);
   ArraySetAsSeries(ExtVolSmoothBuffer,false);
   ArraySetAsSeries(ExtVolDerBuffer,false);
   ArraySetAsSeries(Phase,false);
   ArraySetAsSeries(BougieSurf,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(open,false);
   ArraySetAsSeries(time,false);

//--- initial zero
   if(prev_calculated<1)
     {
      for(i=0; i<Periode; i++)
        {
         MovingBuffer[i]=EMPTY_VALUE;
         UpperBuffer[i]=EMPTY_VALUE;
         LowerBuffer[i]=EMPTY_VALUE;
         UpperBGreen[i]=EMPTY_VALUE;
         UpperBRed[i]=EMPTY_VALUE;
         LowerBGreen[i]=EMPTY_VALUE;
         LowerBRed[i]=EMPTY_VALUE;
         MAPhase1[i]=EMPTY_VALUE;
         EType[i]=EMPTY_VALUE;
         ExtVolSmoothBuffer[i]=EMPTY_VALUE;
         ExtVolDerBuffer[i]=EMPTY_VALUE;
         Phase[i]=0.0;
         BougieSurf[i]=0.0;
        }

     }

   if(prev_calculated>Periode)
     {
      pos=prev_calculated-1;
     }
   else
     {
      pos=prev_calculated;
     }

   for(i=pos; i<rates_total && !IsStopped(); i++)
     {

      //--- middle line
      MovingBuffer[i]=SimpleMA(i,Periode,close);
      //--- calculate and write down StdDev
      EType[i]=StdDev_Func(i,close,MovingBuffer,Periode);

      UpperBuffer[i] = MovingBuffer[i] + EType[i] * EType_Band ; // build BB sup

      LowerBuffer[i] = MovingBuffer[i] - EType[i] * EType_Band ; // and BB inf

      UpperBGreen[i] = UpperBuffer[i] ; // transfert to red and green arrays
      UpperBRed[i] = UpperBuffer[i] ; 

      LowerBGreen[i] = LowerBuffer[i] ; // idem with BB inf
      LowerBRed[i] = LowerBuffer[i] ; 

      if(UpperBuffer[i]>0 && UpperBuffer[i-1]>0 && UpperBuffer[i-2]>0)
        {
         if((UpperBuffer[i] > UpperBuffer[i-1])&&(UpperBuffer[i-1] > UpperBuffer[i-2])) // check if BB sup is uptrend
           {
            UpperBRed[i-1] = EMPTY_VALUE ; 
           }
         else
           {
            if((UpperBuffer[i] < UpperBuffer[i-1])&&(UpperBuffer[i-1] < UpperBuffer[i-2])) // check if BB sup is downtrend
              {
               UpperBGreen[i-1] = EMPTY_VALUE ; 
              }
           }

         if((LowerBuffer[i] > LowerBuffer[i-1])&&(LowerBuffer[i-1] > LowerBuffer[i-2])) // idem BB inf
           {
            LowerBRed[i-1] = EMPTY_VALUE ; 
           }
         else
           {
            if((LowerBuffer[i] < LowerBuffer[i-1])&&(LowerBuffer[i-1] < LowerBuffer[i-2]))
              {
               LowerBGreen[i-1] = EMPTY_VALUE ;
              }
           }
        }

      if(rates_total-i<LimiteAnalyse)
        {

         //+------------------------------------------------------------------+
         //| Calculate volatility and  phases                                 |
         //+------------------------------------------------------------------+
         high_index=ArrayMaximum(EType,Periode,i-Periode+1);
         low_index=ArrayMinimum(EType,Periode,i-Periode+1);

         if(i > Periode)
           {
            ExtVolDerBuffer[i] = (EType[i] - EType[high_index]) / (EType[high_index] - EType[low_index]);
            ExtVolSmoothBuffer[i] = ExtVolDerBuffer[i];
            if(ExtVolSmoothBuffer[i] > 0)
              {
               ExtVolSmoothBuffer[i] = 0;
              }
            ExtVolSmoothBuffer[i]=(ExtVolSmoothBuffer[i]+1.0)*100.0;// indic between 0 and 100
           }


         if(UpperBuffer[i-1]+(ToleranceBBPhase1*Point)>=UpperBuffer[i] && LowerBuffer[i-1]-(ToleranceBBPhase1*Point)<=LowerBuffer[i]
            && ExtVolSmoothBuffer[i]>=0.0 && ExtVolSmoothBuffer[i]<=SeuilPhase1)
           {
            //Phase 1
            MAPhase1[i-1]=MovingBuffer[i-1];
            MAPhase1[i]=MovingBuffer[i];
            Phase[i]=1.0;
           }
         else
           {
            MAPhase1[i]=EMPTY_VALUE;
            Phase[i]=0;
           }

         phase1Prec=false;
         for(j=i-EcartMaxPhase1; j<=i; j++)
           {
            if(Phase[j]==1.0)
              {
               phase1Prec=true;
              }
           }

         //+------------------------------------------------------------------+
         //| Calculate surfing candles                                  |
         //+------------------------------------------------------------------+
         if((i > Periode && (phase1Prec)) || (BougieSurf[i-1]!=0.0 && BougieSurf[i-1]!=EMPTY_VALUE))
           {
            if(BougieSurf[i]==EMPTY_VALUE)
              {
               BougieSurf[i]=0;
              }
            //surfer on BB sup
            if(close[i]>=UpperBuffer[i] || open[i]>=UpperBuffer[i])
              {
               if(BougieSurf[i-1]!=EMPTY_VALUE && BougieSurf[i-1]>=0)
                 {
                  BougieSurf[i]=BougieSurf[i-1]+1;
                 }
               else
                 {
                  BougieSurf[i]=1;
                 }
               //add text
               CreateText(baseObj+"Surf_"+(i),time[i],high[i],BougieSurf[i], Red,ANCHOR_LOWER);
              }
            else
              {

               //surfer on BB inf
               if(close[i]<=LowerBuffer[i] || open[i]<=LowerBuffer[i])
                 {
                  if(BougieSurf[i-1]!=EMPTY_VALUE && BougieSurf[i-1]<=0)
                    {
                     BougieSurf[i]=BougieSurf[i-1]-1;
                    }
                  else
                    {
                     BougieSurf[i]=-1;
                    }
                  //write text
                  CreateText(baseObj+"Surf_"+(i),time[i],low[i],(BougieSurf[i]*-1), Red,ANCHOR_UPPER);
                 }
               else
                 {
                  BougieSurf[i]=0;
                 }
              }
           }
        }
     } 


//----
   return(0);
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
//| delete created objects based on a pattern                        |
//+------------------------------------------------------------------+
void DeleteObjectsByString(string Search, int ObjectType=-1)
  {
   int TotalObject = ObjectsTotal(0,0,-1);
   for(int i = 0; i <= TotalObject ; i++)
     {
      if(StringFind(ObjectName(0, i, 0, ObjectType), Search, 0) > -1)
        {
         ObjectDelete(0,ObjectName(0,i,0,-1));
        }
     }

  }

//+------------------------------------------------------------------+
//| write text on the graph                                          |
//+------------------------------------------------------------------+
void CreateText(string name,datetime candle,double price,string text, color clr, int anchor)
  {
   ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_TEXT,0,candle,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
