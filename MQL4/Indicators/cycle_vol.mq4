//+------------------------------------------------------------------+
//|                              Cycle de volatilité                 |
//|                              Volatility Cycle                    |
//| Based on an indicator from Gousset / Vitale                      |
//| modified by B. DURAND                                            |
//+------------------------------------------------------------------+
#property copyright "G. GOUSSET  N. VITALE B.DURAND"
#property version   "1.00"
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 LightSeaGreen // MA 


//---- indicator parameters
extern int Periode = 20;
extern double EType_Band = 2.0;

//---- buffers
double MovingBuffer[]; // for MA
double EType[] ; // StD
double ExtVolDerBuffer[];// Volatility

//+------------------------------------------------------------------+
//| initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---- indicators
   IndicatorDigits(Digits);
   IndicatorBuffers(3);

   SetIndexStyle(0,DRAW_LINE,0,1);
   SetIndexBuffer(0,MovingBuffer);
   SetIndexLabel(0,"MA "+Periode);

   SetIndexStyle(1,DRAW_NONE,0,2);
   SetIndexBuffer(1,EType);
   SetIndexLabel(1,"Std Dev");

   SetIndexStyle(2,DRAW_NONE,0,2);
   SetIndexBuffer(2,ExtVolDerBuffer);
   SetIndexLabel(2,"Volatility");

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

   int limit=Bars-Periode;

   if(rates_total<=Periode)
     {
      return(0);
     }

   ArraySetAsSeries(MovingBuffer,false);
   ArraySetAsSeries(EType,false);
   ArraySetAsSeries(ExtVolDerBuffer,false);
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
         EType[i]=EMPTY_VALUE;
         ExtVolDerBuffer[i]=EMPTY_VALUE;
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

   for(i=pos; i<rates_total ; i++)
     {

      //--- middle line
      MovingBuffer[i]=SimpleMA(i,Periode,close);
      //--- calculate and write down StdDev
      EType[i]=StdDev_Func(i,close,MovingBuffer,Periode);

      //+------------------------------------------------------------------+
      //| Calculate volatility                                             |
      //+------------------------------------------------------------------+
      high_index=ArrayMaximum(EType,Periode,i-Periode+1);
      low_index=ArrayMinimum(EType,Periode,i-Periode+1);

      if(i > Periode)
        {
         ExtVolDerBuffer[i] = (EType[i] - EType[high_index]) / (EType[high_index] - EType[low_index]);
         ExtVolDerBuffer[i]=(ExtVolDerBuffer[i]+1.0)*100.0;// indic betwwen 0 and 100
        }
     }

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
