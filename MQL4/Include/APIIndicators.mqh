//+------------------------------------------------------------------+
//|                                                APIIndicators.mqh |
//|                                                    Benoit Durand |
//|                                              http://www.mql4.com |
//| for a symbol and a timeframe, receive an indicator               |
//| and his param by string and returns the value in float           |
//| example getIndicatorFromParam(symbol, timeframe,"MM2_ADX_go:9,5,10,1,20", handle)
//+------------------------------------------------------------------+
#property copyright "Benoit Durand"
#property link      "http://www.mql4.com"
#property strict
#include <Indicators.mqh>
#include <FileManagement.mqh>

//+------------------------------------------------------------------+
//| list of functions                                                |
//+------------------------------------------------------------------+
// DumbFixeVal : returns value passed
// MM2_ADX_go : returns 1 or -1 if MM_Fast > MM_slow and if they are above threshold else returns 0
// MM_price_dif : returns difference between MM and the price
// MM_price : returns MA price
// MM_price_dif_double : returns the difference between 2 MA if price > first MA
// MME2_close_dif : returns the difference between 2 EMA
// MMS2_close_dif : returns the difference between 2 SMA
// MMS2_close_sens : returns 1 if 2 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
// MME2_close_sens : returns 1 if 2 EMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
// MMS2_close_sens_n : returns 1 if 2 SMA are in a bull trend (short above long) on the last n candles, -1 if down trend otherwise 0 (both up and down)
// MMS2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
// MME2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
// MM2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
// MMS3_close_sens : returns 1 if 3 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
// MM4_close_sens : returns 1 if 4 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
// MM2_RSI_dif : returns the difference between 2 SMA of the RSI
// MM2_RSI_dif_seuil_go : returns the difference between 2 SMA of the RSI and check if go above or below the given threshold
// MM2_RSI_dif_seuil_simple_go : if fast MA on RSI is above slow MA and is above the threshold returns 1
// MM2_RSI_dif_seuil_simple_go_n : if fast MA on RSI is above slow MA on last n candles and is above the threshold returns 1
// MM2_RSI_dif_simple_go : returns the difference between 2 SMA on RSI
// RSI_val : returns the RSI value
// MM_RSI_val_Seuil : returns 1.0 if the SMA on RSI val is above the threshold+margin and -1.0 if below
// RSI_val_Seuil : returns 1.0 if the RSI val is above the threshold+margin and -1.0 if below
// BB_pos : returns position of price retaive to the Bollinger Bands
// BB_reject : returns 1 if a candle closed inside BB but went below the low BB
// BB_Surfeuse_go : returns 1 if the candle is surfing on the upper BB, -1 if surfing on the lower BB
// TR_2_STD_go : returns 1 if true range is superior to 2 standard deviation and it's a up candle
// CCI_val : returns the CCI value ex : 52.4
// CCI_val_seuil : returns the CCI value relative to a threshold ex : -52.4
// CCI_retour_seuil : returns 1 if CCI passed above thresold during last n candles and returned below the threshold
// Stoch_val : returns the value of a Stochastic line ex : 52.4
// Stoch_val_Signal : returns 1 if the stock main line is above the signal line else -1
// Stoch_val_Signal_Go : returns 1 if the main line is above the signal line since the last candle
// Stoch_pos_seuil : returns 1 if the choosen line is above 50+threshold or -1 if below 50-threshold otherwise 0
// Stoch_retour_seuil : returns 1 if the stoch line passed above thresold during last n candles and returned below the threshold
// Phase_val : returns the BB phase (1,2,3 or 4)
// Cycle_Vol_Seuil_go : returns 1 if cycle volatility is above the threshold else 0
// Phase_4_1_val : returns the BB phase if it's a phase 1 or 4 else 0
// Phase_4_1_go : returns 6666.0 (special value) if it's a BB phase 1 or 4 else 0
// Phase_Sens_val : returns the trend of the BB phase : 1 for long -1 for short
// Phase_Surfeuse_val : returns the number of the current surfing candle, positive value if upper BB, negative if lower BB else (no surfing) 0
// Phase_2_en_cours : returns if we are in BB phase 2, option with trend 1 for long -1 for short
// Phase_Autiste_go : returns if we are in BB phase 2 or 3, option with trend 1 for long -1 for short
// Phase_Autiste_P1_go : returns if we are in BB phase 1,2 or 3 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
// Phase_P1_P2_go : returns if we are in BB phase 1 or 2 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
// Phase_2_go : returns if we are in BB phase 2 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
// Ichimoku_line_price : returns value of an ichimoku  line
// Ichimoku_line_price_dif : returns the difference between a ichimoku line and the price
// Ichimoku_line_go : returns 1 if the price just crossed the ichimoku line up way during the last n bars
// Kijun_Tenkan_Direction : returns 1 if the price > Tenkan  >= Kijun returns -1 if the prix < Kijun <= Tenkan else 0
// Ichimoku_Alignment : returns 1 if selected lines are aligned in a bull way
// Ichimoku_Alignment_Go : returns 1 if selected lines became aligned in a bull way in last n bars
// Aroon_Go : returns 1 if Aroon lines crossed during the last n candles
// Aroon_Direction : returns 1 if Aroon is up  else 0
// Aroon_Go_Seuil : returns 1 if the Aroon bull line >= threshold during last n candles
// Aroon_Direction_Seuil : returns 1 if Aroon's bull line is above treshold,
// RVI_Go : returns 1 if RVI > Signal+margin, -1 if RVI < signal- margin else 0
// RVI_Direction : returns 1 if RVI > Signal+margin, -1 if RVI < signal- margin else 0
// REX_Go : returns 1 if REX > Signal+margin, -1 if REX < signal- margin else 0
// Cassure_Go : returns 1 if price > highest of last n candles, -1 if price < lowest of last n candles else 0
// Point_Pivot_Forex_Sens : returns 1 if price > open(W1,0) and > close(W1,1), -1 if price < open(W1,0) and < close(W1,1) else 0
// Point_Pivot_Index_Sens : returns 1 if price > open and close
// BullsVsBears_Go : returns 1 if Bulls and Bears+margin crossed in bulls way during last N candles
// BullsVsBears_Direction : returns 1 if Bulls and Bears+margin is in bulls way else -1
// ASH_Go : returns 1 if ASH lines+marge crossed in bulls way during last N candles
// ASH_Direction : returns 1 if ASH lines+margin is in bulls side else returns -1
// SSL_Channel_Go : returns 1 if SSL lines crossed in a bull trend during the last n candles
// SSL_Channel_Direction : returns 1 SSL Up line is above down line else returns -1
// Distance_BL_Go : returns 1 if price - base line is less than N ATR (NNFX system)
// WAE_En_Cours : returns 1 if WAE is green abd above his line, -1 if it's red abd above his line else 0
// ALMA_Direction : returns the direction of ALMA : -1/ 1
// ALMA_Go : returns 1 if price crossed the ALMA line in last N bars in bull way
// Kaufman_Direction : returns the direction of Kaufman : -1/ 1
// Kaufman_Go : returns 1 if price crossed the Kaufman line in last N bars in bull way
// Vortex_Go : returns 1 if Plus and Minus+margin crossed in bulls way during last N candles
// Vortex_Direction : returns 1 if Plus and Minus+margin is in bulls way else -1
// DEMA_Direction : returns the direction of DEMA : -1/ 1
// DEMA_Go : returns 1 if price crossed the DEMA line in last N bars in bull way
// KAMA_Direction : returns the direction of KAMA : -1/ 1
// KAMA_Go : returns 1 if price crossed the KAMA line in last N bars in bull way
// HLCTrend_Direction : returns the direction of HLCTrend : -1/ 1
// HLCTrend_Go : returns 1 if price crossed the KAMA line in last N bars in bull way
// QQE_Direction : returns the direction of QQE : -1/ 1
// QQE_Go : returns 1 if price crossed the line in last N bars in bull way
// Didi_Direction : returns the direction of Didi's slow line : -1/ 1
// Didi_Go : returns 1 if slow line crossed the medium line in last N bars in bull way
// BBTrend_Flat_Direction : returns the direction of BBTrend_Flat : -1/ 1 / 0 if flat
// BBTrend_Flat_Go : returns 1 if BB Trend went green in last N bars
// MACD_Go : returns 1 if MACD line crossed MACD signal in last bar in bull way AND MACD line is below 0
// Reverse_Candle_Go : returns 1 the candle selected is a bullish reverse candle, big low wick
//
//+------------------------------------------------------------------+

/* returns -9999 if there is an error                                      */
/* returns 0 for neutral                                                   */
/* returns <0 for down trend                                               */
/* returns >0 for up trend                                                 */
/* returns -5555 special value for neutral trend BB phase 1                */
/* returns 5555 special value for indicator without trend like volatility  */
/* see description of each sub function for details                        */
/***************************************************************************/
double getIndicatorFromParam(string symbol=NULL, int timeframe=0, string param="method;param,param2", int handle=0)
  {
   string resMethode[], resParam[], methode="",listParam="";
   double resIndic=-9999;

   if(StringSplit(param,StringGetCharacter(":",0),resMethode)==2)
     {
      methode=resMethode[0];
      listParam=resMethode[1];

      if(StringSplit(listParam,StringGetCharacter(",",0),resParam)>0)
        {
         // for each method, we have to check the numbers of input parameters !!!

         //DumbFixeVal : returns value passed
         //param : value
         //ex : DumbFixeVal:1.0
         if(methode=="DumbFixeVal")
           {
            if(ArraySize(resParam)==1)
              {
               resIndic=StrToDouble(resParam[0]);
              }
            return resIndic;
           }

         //MM2_ADX_go : returns 1 or -1 if MM_Fast > MM_slow and if they are above threshold else returns 0
         //1 if D+>=D- else -1
         //param : param ADX, nb candles MA Fast, nb candles MA Slow, shift, threshold to use default 20
         //ex : MM2_ADX_go:9,5,10,1,20
         if(methode=="MM2_ADX_go")
           {
            int seuil=20;

            if(ArraySize(resParam)==5)
              {
               seuil=StrToInteger(resParam[4]);
              }

            if(ArraySize(resParam)>=4)
              {
               double ma_fast_adx=getMAADXVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), StrToInteger(resParam[3]));
               double ma_slow_adx=getMAADXVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), StrToInteger(resParam[3]));
               double DPlus=iADX(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,MODE_PLUSDI,StrToInteger(resParam[3]));
               double DMoins=iADX(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,MODE_MINUSDI,StrToInteger(resParam[3]));
               double dif_ma_adx=ma_fast_adx-ma_slow_adx;
               if(dif_ma_adx>0 && ma_fast_adx>seuil && ma_slow_adx>seuil)
                 {
                  if(DPlus>=DMoins)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     resIndic=-1.0;
                    }
                 }
               else
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         //MM_price_dif : returns difference between MM and the price
         //param : nb candles MM, mode, value to use, shift, inversion
         //ex : MM_price_dif:3,MODE_EMA,PRICE_HIGH,0,-1
         if(methode=="MM_price_dif")
           {
            if(ArraySize(resParam)>=4)
              {
               int inversion=1;
               int nb_candles=StrToInteger(resParam[0]);
               int shift=StrToInteger(resParam[3]);
               int mode=-1,applied=-1;
               string modeParam=resParam[1];
               string appliedParam=resParam[2];

               if(modeParam=="MODE_SMA")
                 {
                  mode=MODE_SMA;
                 }
               if(modeParam=="MODE_EMA")
                 {
                  mode=MODE_EMA;
                 }

               if(appliedParam=="PRICE_CLOSE")
                 {
                  applied=PRICE_CLOSE;
                 }
               if(appliedParam=="PRICE_HIGH")
                 {
                  applied=PRICE_HIGH;
                 }
               if(appliedParam=="PRICE_LOW")
                 {
                  applied=PRICE_LOW;
                 }

               if(ArraySize(resParam)==5)
                 {
                  inversion= StrToInteger(resParam[4]);
                 }

               if(nb_candles<=0)
                 {
                  nb_candles=1;  // if bad input
                 }
               double MM =iMA(symbol,timeframe,nb_candles,0,mode,applied,shift);
               resIndic=iClose(symbol,timeframe,shift)-MM;
               resIndic=resIndic*inversion;
              }
            return resIndic;
           }

         // MM_price : returns MA price
         //param : nb candles MM, mode, value to use, shift
         //ex : MM_price:3,MODE_EMA,PRICE_HIGH,0
         if(methode=="MM_price")
           {
            if(ArraySize(resParam)==4)
              {
               int nb_candles=StrToInteger(resParam[0]);
               if(nb_candles<=0)
                 {
                  nb_candles=1;  // en cas de paramètre erroné lors de l'initialisation
                 }
               resIndic =iMA(symbol,timeframe,nb_candles,0,StrToInteger(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]));
               logMe(handle,1,"getIndicatorFromParam SMA nb bar : "+nb_candles+" mode:"+resParam[2]+" resIndic :   "+resIndic+"  ",1);
              }
            return resIndic;
           }

         //MM_price_dif_double : returns the difference between 2 MA if price > first MA
         // returns the difference (negative) between 2 MA if < the second MA
         //else returns 0
         //param : nb candles MM, mode, value to use first MA,value to use second MA,shift
         //ex : MM_price_dif_double:3,MODE_SMA,PRICE_HIGH,PRICE_LOW,1
         if(methode=="MM_price_dif_double")
           {
            if(ArraySize(resParam)==5)
              {
               int nb_candles=StrToInteger(resParam[0]);
               resIndic=0.0;
               if(nb_candles<=0)
                 {
                  nb_candles=1;  // if bad input
                 }

               double MM1 =iMA(symbol,timeframe,nb_candles,0,StrToInteger(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[4]));
               double MM2 =iMA(symbol,timeframe,nb_candles,0,StrToInteger(resParam[1]),StrToInteger(resParam[3]),StrToInteger(resParam[4]));

               if(MarketInfo(symbol,MODE_BID)>MM1)
                 {
                  resIndic=MarketInfo(symbol,MODE_BID)-MM1;
                 }
               else
                 {
                  if(MarketInfo(symbol,MODE_BID)<MM2)
                    {
                     resIndic=MarketInfo(symbol,MODE_BID)-MM2;
                    }
                 }
              }
            return resIndic;
           }

         //MME2_close_dif : returns the difference between 2 EMA
         //param : nb candles MA Fast, nb candles MA Slow, shift
         //ex : MME2_close_dif:5,10,1
         if(methode=="MME2_close_dif")
           {
            if(ArraySize(resParam)==3)
              {
               int nb_candles=StrToInteger(resParam[0]);
               if(nb_candles<=0)
                 {
                  nb_candles=1;  // if wronf input
                 }
               resIndic =getDifMAVal(symbol, timeframe,nb_candles,StrToInteger(resParam[1]),MODE_EMA,PRICE_CLOSE, StrToInteger(resParam[2]), StrToInteger(resParam[2]));
              }
            return resIndic;
           }

         //MMS2_close_dif : returns the difference between 2 SMA
         //param : nb candles MA Fast, nb candles MA Slow, shift
         //ex : MMS2_close_dif:5,10,1
         if(methode=="MMS2_close_dif")
           {
            if(ArraySize(resParam)==3)
              {
               int nb_candles=StrToInteger(resParam[0]);
               if(nb_candles<=0)
                 {
                  nb_candles=1;  // if wronf input
                 }
               resIndic =getDifMAVal(symbol, timeframe,nb_candles,StrToInteger(resParam[1]),MODE_SMA,PRICE_CLOSE, StrToInteger(resParam[2]), StrToInteger(resParam[2]));
              }
            return resIndic;
           }

         //MMS2_close_sens : returns 1 if 2 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
         //param : nb candles MA 1, nb candles MA 2, shift, -1 to inverse result
         // nb candles inputs must be ascending
         //ex : MMS2_close_sens:1,10,1,-1
         if(methode=="MMS2_close_sens")
           {
            int inversion=1;
            if(ArraySize(resParam)>=3)
              {
               if(ArraySize(resParam)==4)
                 {
                  inversion=StrToInteger(resParam[3]);
                 }

               resIndic=0.0;
               double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),MODE_SMA,PRICE_CLOSE, StrToInteger(resParam[2]), StrToInteger(resParam[2]));

               if(resDif1_2>0.0)
                 {
                  resIndic=1.0;
                 }
               if(resDif1_2<0.0)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic*inversion;
           }

         //MME2_close_sens :  returns 1 if 2 EMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
         //param : nb candles MA 1, nb candles MA 2, shift, -1 to inverse result
         // nb candles inputs must be ascending
         //ex : MME2_close_sens:1,10,1-1
         if(methode=="MME2_close_sens")
           {
            int inversion=1;
            if(ArraySize(resParam)>=3)
              {
               if(ArraySize(resParam)==4)
                 {
                  inversion=StrToInteger(resParam[3]);
                 }
               resIndic=0.0;
               double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),MODE_EMA,PRICE_CLOSE, StrToInteger(resParam[2]), StrToInteger(resParam[2]));

               if(resDif1_2>0.0)
                 {
                  resIndic=1.0;
                 }
               if(resDif1_2<0.0)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic*inversion;
           }

         //MMS2_close_sens_n : returns 1 if 2 SMA are in a bull trend (short above long) on the last n candles, -1 if down trend otherwise 0 (both up and down)
         //param : nb candles MA 1, nb candles MA 2, shift, nb candles to check,-1 to inverse result
         // nb candles inputs must be ascending
         //ex : MMS2_close_sens_n:1,10,1,3,-1
         if(methode=="MMS2_close_sens_n")
           {
            int inversion=1;
            if(ArraySize(resParam)>=4)
              {
               if(ArraySize(resParam)==5)
                 {
                  inversion=StrToInteger(resParam[4]);
                 }
               resIndic=9.0;
               int shift=StrToInteger(resParam[2]);

               for(int i=shift; i<=shift+StrToInteger(resParam[3]); i++)
                 {
                  double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),MODE_SMA,PRICE_CLOSE, shift+i, shift+i);
                  if(resDif1_2>0.0 && resIndic==9.0)
                    {
                     resIndic=1.0;
                    }
                  if(resDif1_2>0.0 && resIndic==-1.0)
                    {
                     resIndic=0.0;
                    }
                  if(resDif1_2<0.0 && resIndic==9.0)
                    {
                     resIndic=-1.0;
                    }
                  if(resDif1_2<0.0 && resIndic==1.0)
                    {
                     resIndic=0.0;
                    }
                 }
               if(resIndic==9.0)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic*inversion;
           }

         //MMS2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
         // returns -1 if they crossed in a down way else returns 0
         //param : mode MA, param SMA 1, param SMA 2, shift, nb candles checked,-1 to inverse return
         // SMA must be in incresing order
         //ex : MMS2_close_go:1,10,1,7,-1
         if(methode=="MMS2_close_go")
           {
            if(ArraySize(resParam)>=4)
              {
               string APIMM="MM2_close_go:MODE_SMA,"+resParam[0]+","+resParam[1]+","+resParam[2]+","+resParam[3];

               if(ArraySize(resParam)>4)
                 {
                  APIMM+=","+resParam[4];
                 }
               resIndic= getIndicatorFromParam(symbol,  timeframe,APIMM,handle);
              }
            return resIndic;
           }

         //MME2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
         // returns -1 if they crossed in a down way else returns 0
         //param : mode MA, param SMA 1, param SMA 2, shift, nb candles checked,-1 to inverse return
         // SMA must be in incresing order
         //ex : MME2_close_go:1,10,1,7,-1
         if(methode=="MME2_close_go")
           {
            if(ArraySize(resParam)>=4)
              {
               string APIMM="MM2_close_go:MODE_EMA,"+resParam[0]+","+resParam[1]+","+resParam[2]+","+resParam[3];

               if(ArraySize(resParam)>4)
                 {
                  APIMM+=","+resParam[4];
                 }
               resIndic= getIndicatorFromParam(symbol,  timeframe,APIMM,handle);
              }
            return resIndic;
           }

         //MM2_close_go : returns 1 if the 2 SMA crossed in the last n candles in a upper way
         // returns -1 if they crossed in a down way else returns 0
         //param : mode MA, param SMA 1, param SMA 2, shift, nb candles checked,-1 to inverse result
         // SMA must be in incresing order
         //ex : MM2_close_go:MODE_SMA,1,10,1,7,-1
         if(methode=="MM2_close_go")
           {
            int inversion=1;
            if(ArraySize(resParam)>=5)
              {
               if(ArraySize(resParam)==6)
                 {
                  inversion=StrToInteger(resParam[5]);
                 }
               resIndic=0.0;
               int shift=StrToInteger(resParam[3]),mode;
               int nbCandles=StrToInteger(resParam[4]);

               if(resParam[0]=="MODE_SMA")
                 {
                  mode=MODE_SMA;
                 }
               if(resParam[0]=="MODE_EMA")
                 {
                  mode=MODE_EMA;
                 }

               bool cross=false;
               double direction=getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[2]),mode,PRICE_CLOSE, shift, shift);

               int i=shift;
               while(i<=shift+nbCandles && !cross)
                 {
                  double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[2]),mode,PRICE_CLOSE, i, i);
                  if((direction>0 && resDif1_2<0) ||(direction<0 && resDif1_2>0))
                    {
                     cross=true;
                     i++;
                    }
                 }
               if(cross)
                 {
                  if(direction>0)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     resIndic=-1.0;
                    }
                 }
              }
            return resIndic*inversion;
           }

         //MMS3_close_sens : returns 1 if 3 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
         //param : nb candles MA 1, nb candles MA 2, nb candles MA 3, shift
         // nb candles must be in incresing order
         //ex : MMS3_close_sens:1,5,10,1
         if(methode=="MMS3_close_sens")
           {
            if(ArraySize(resParam)==4)
              {
               resIndic=0.0;
               double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),MODE_SMA,PRICE_CLOSE, StrToInteger(resParam[3]), StrToInteger(resParam[3]));
               double resDif1_3 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[2]),MODE_SMA,PRICE_CLOSE, StrToInteger(resParam[3]), StrToInteger(resParam[3]));
               double resDif2_3 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,PRICE_CLOSE, StrToInteger(resParam[3]), StrToInteger(resParam[3]));

               if(resDif1_2>0.0 && resDif1_3>0.0 && resDif2_3>0.0)
                 {
                  resIndic=1.0;
                 }
               if(resDif1_2<0.0 && resDif1_3<0.0 && resDif2_3<0.0)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //MM4_close_sens : returns 1 if 4 SMA are in a bull trend (fast above slow), -1 if down trend otherwise 0
         //param : mode MA,nb candles MA 1, nb candles MA 2, nb candles MA 3, nb candles MA 4, shift
         // nb candles must be in incresing order
         //ex : MM4_close_sens:MODE_SMA,1,5,10,20,1
         if(methode=="MM4_close_sens")
           {
            if(ArraySize(resParam)==6)
              {
               resIndic=0.0;
               int shift=StrToInteger(resParam[5]), mode;

               if(resParam[0]=="MODE_SMA")
                 {
                  mode=MODE_SMA;
                 }
               if(resParam[0]=="MODE_EMA")
                 {
                  mode=MODE_EMA;
                 }

               double resDif1_2 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[2]),mode,PRICE_CLOSE, shift, shift);
               double resDif1_3 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[3]),mode,PRICE_CLOSE, shift, shift);
               double resDif1_4 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[1]),StrToInteger(resParam[4]),mode,PRICE_CLOSE, shift, shift);
               double resDif2_3 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[2]),StrToInteger(resParam[3]),mode,PRICE_CLOSE, shift, shift);
               double resDif2_4 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[2]),StrToInteger(resParam[4]),mode,PRICE_CLOSE, shift, shift);
               double resDif3_4 =getDifMAVal(symbol, timeframe,StrToInteger(resParam[3]),StrToInteger(resParam[4]),mode,PRICE_CLOSE, shift, shift);

               if(resDif1_2>0.0 && resDif1_3>0.0 && resDif1_4>0.0 && resDif2_3>0.0 && resDif2_4>0.0 && resDif3_4>0.0)
                 {
                  resIndic=1.0;
                 }
               if(resDif1_2<0.0 && resDif1_3<0.0 && resDif1_4<0.0 && resDif2_3<0.0 && resDif2_4<0.0 && resDif3_4<0.0)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //MM2_RSI_dif : returns the difference between 2 SMA of the RSI
         //param : param RSI, nb candles MA Fast, nb candles MA Slow, shift
         //ex : MM2_RSI_dif:9,5,10,1
         if(methode=="MM2_RSI_dif")
           {
            if(ArraySize(resParam)==4)
              {
               double ma_fast_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), StrToInteger(resParam[3]));
               double ma_slow_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), StrToInteger(resParam[3]));
               resIndic=ma_fast_rsi-ma_slow_rsi;
              }
            return resIndic;
           }

         //MM2_RSI_dif_seuil_go : returns the difference between 2 SMA of the RSI and check if go above or below the given threshold
         //if both MA go through the threshold, result forced to 2 or -2 ex : >60 => go buy
         // if the trend is bullish but not forced returns 1 or -1
         //param : param RSI, nb candles MA Fast, nb candles MA Slow, shift, threshold
         //ex : MM2_RSI_dif_seuil_go:9,5,10,1,10
         if(methode=="MM2_RSI_dif_seuil_go")
           {
            if(ArraySize(resParam)==5)
              {
               int seuil=StrToInteger(resParam[4]);
               double ma_fast_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), StrToInteger(resParam[3]));
               double ma_slow_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), StrToInteger(resParam[3]));

               double dif_rsi=ma_fast_rsi-ma_slow_rsi;

               if(dif_rsi>0 && ma_fast_rsi>50+seuil && ma_slow_rsi>50+seuil && ma_fast_rsi>=ma_slow_rsi)
                 {
                  resIndic=2.0;
                 }
               else
                 {
                  if(dif_rsi<0 && ma_fast_rsi<50-seuil && ma_slow_rsi<50-seuil && ma_fast_rsi<=ma_slow_rsi)
                    {
                     resIndic=-2.0;
                    }
                  else
                    {
                     if(dif_rsi>0 && ma_fast_rsi>50-seuil && ma_slow_rsi>50-seuil)
                       {
                        resIndic=1.0;
                       }
                     else
                       {
                        if(dif_rsi<0 && ma_fast_rsi<50+seuil && ma_slow_rsi<50+seuil)
                          {
                           resIndic=-1.0;
                          }
                        else
                          {
                           resIndic=0.0;
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         //MM2_RSI_dif_seuil_simple_go :
         //if fast MA on RSI is above slow MA and is above the threshold returns 1
         // if fast MA on RSI is below slow MA and is below the threshold returns 1
         //param : param RSI, nb candles MA Fast, nb candles MA Slow, shift, threshold
         //ex : MM2_RSI_dif_seuil_simple_go:9,5,10,1,10
         if(methode=="MM2_RSI_dif_seuil_simple_go")
           {
            if(ArraySize(resParam)==5)
              {
               int seuil=StrToInteger(resParam[4]);
               double ma_fast_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), StrToInteger(resParam[3]));
               double ma_slow_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), StrToInteger(resParam[3]));

               double dif_rsi=ma_fast_rsi-ma_slow_rsi;

               if(dif_rsi>0 && ma_fast_rsi>50+seuil && ma_fast_rsi>=ma_slow_rsi)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  if(dif_rsi<0 && ma_fast_rsi<50-seuil && ma_fast_rsi<=ma_slow_rsi)
                    {
                     resIndic=-1.0;
                    }
                  else
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }


         //MM2_RSI_dif_seuil_simple_go_n :
         //if fast MA on RSI is above slow MA on last n candles and is above the threshold returns 1
         // if fast MA on RSI is below slow MA on last n candles and is below the threshold returns 1
         //if mixed result returns 0.0 and otherwise returns 99.0
         //param : param RSI, nb candles MA Fast, nb candles MA Slow, shift, threshold, nb candles to check
         //ex : MM2_RSI_dif_seuil_simple_go:9,5,10,1,10,3
         if(methode=="MM2_RSI_dif_seuil_simple_go_n")
           {
            if(ArraySize(resParam)==6)
              {
               int seuil=StrToInteger(resParam[4]);
               int shift=StrToInteger(resParam[3]);

               resIndic=99.0;

               for(int i=shift; i<=shift+StrToInteger(resParam[5]); i++)
                 {

                  double ma_fast_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), shift+i);
                  double ma_slow_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), shift+i);

                  double dif_rsi=ma_fast_rsi-ma_slow_rsi;

                  if(dif_rsi>0 && ma_fast_rsi>50+seuil && ma_fast_rsi>=ma_slow_rsi && resIndic==9.0)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     if(dif_rsi>0 && ma_fast_rsi>50+seuil && ma_fast_rsi>=ma_slow_rsi && resIndic==-1.0)
                       {
                        resIndic=0.0;
                       }
                     else
                       {

                        if(dif_rsi<0 && ma_fast_rsi<50-seuil && ma_fast_rsi<=ma_slow_rsi && resIndic==9.0)
                          {
                           resIndic=-1.0;
                          }
                        else
                          {
                           if(dif_rsi<0 && ma_fast_rsi<50-seuil && ma_fast_rsi<=ma_slow_rsi && resIndic==1.0)
                             {
                              resIndic=0.0;
                             }
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         //MM2_RSI_dif_simple_go : returns the difference between 2 SMA on RSI
         //if the fast MA is above the slow MA returns 1.0
         // if the fast MA is below the slow MA returns -1.0
         //param : param RSI, nb candles MA Fast, nb candles MA Slow, shift
         //ex : MM2_RSI_dif_seuil_simple_go:9,5,10,1
         if(methode=="MM2_RSI_dif_simple_go")
           {
            if(ArraySize(resParam)==4)
              {
               double ma_fast_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]), StrToInteger(resParam[3]));
               double ma_slow_rsi=getMARSIVal(symbol, timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[2]), StrToInteger(resParam[3]));

               double dif_rsi=ma_fast_rsi-ma_slow_rsi;

               if(dif_rsi>0 && ma_fast_rsi>=ma_slow_rsi)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  if(dif_rsi<0 && ma_fast_rsi<=ma_slow_rsi)
                    {
                     resIndic=-1.0;
                    }
                  else
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }

         //RSI_val : returns the RSI value
         //param : param RSI, shift
         //ex : RSI_val:14,1
         if(methode=="RSI_val")
           {
            if(ArraySize(resParam)==2)
              {
               resIndic=iRSI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]));
              }
            return resIndic;
           }

         //MM_RSI_val_Seuil : returns 1.0 if the SMA on RSI val is above the threshold+margin and -1.0 if below
         //param : param RSI, lnb candles for MA, shift, threshold, margin for 0
         //ex : RSI_val_Seuil:14,5,1,50,10
         if(methode=="MM_RSI_val_Seuil")
           {
            double res=0.0;

            if(ArraySize(resParam)==5)
              {
               resIndic=getMARSIVal(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]),StrToInteger(resParam[2]));
               if(resIndic>StrToInteger(resParam[3])+StrToInteger(resParam[4]))
                 {
                  res=1.0;
                 }
               if(resIndic<StrToInteger(resParam[3])-StrToInteger(resParam[4]))
                 {
                  res=-1.0;
                 }
              }
            return res;
           }

         //RSI_val_Seuil : returns 1.0 if the RSI val is above the threshold+margin and -1.0 if below
         //param : param RSI, shift, threshold, margin for 0
         //ex : RSI_val_Seuil:14,1,50,10
         if(methode=="RSI_val_Seuil")
           {
            double res=0.0;

            if(ArraySize(resParam)==4)
              {
               resIndic=iRSI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]));
               if(resIndic>StrToInteger(resParam[2])+StrToInteger(resParam[3]))
                 {
                  res=1.0;
                 }
               if(resIndic<StrToInteger(resParam[2])-StrToInteger(resParam[3]))
                 {
                  res=-1.0;
                 }
              }
            return res;
           }

         //BB_pos : returns position of price retaive to the Bollinger Bands
         //returns 2 if above the bands, 1 if between main and upper, -1 if between main and lower, -2 if below the bands
         //param : input Bollinger, shift
         //ex : BB_pos:20,0
         if(methode=="BB_pos")
           {
            if(ArraySize(resParam)==2)
              {
               double valMain=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,0,StrToInteger(resParam[1]));
               double valUpper=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,1,StrToInteger(resParam[1]));
               double valLower=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,2,StrToInteger(resParam[1]));

               if(MarketInfo(symbol,MODE_BID)>valUpper)
                 {
                  resIndic=2.0;
                 }
               else
                 {
                  if(MarketInfo(symbol,MODE_BID)>valMain)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     if(MarketInfo(symbol,MODE_BID)>valLower)
                       {
                        resIndic=-1.0;
                       }
                     else
                       {
                        if(MarketInfo(symbol,MODE_BID)<valLower)
                          {
                           resIndic=-2.0;
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         // BB_reject : returns 1 if a cadnle closed inside BB but went below the low BB
         //returns -1 if a cadnle closed inside BB but went above the high BB
         //param : param moyenne Bollinger, shift
         //ex : BB_reject:20,0
         if(methode=="BB_reject")
           {
            if(ArraySize(resParam)==2)
              {
               resIndic=0.0;
               int shift=StrToInteger(resParam[1]);
               double valUpper=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,1,shift);
               double valLower=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,2,shift);

               if(iClose(symbol,timeframe,shift)>valLower && iClose(symbol,timeframe,shift)<valUpper)
                 {
                  if(iLow(symbol,timeframe,shift)<valLower)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     if(iHigh(symbol,timeframe,shift)>valUpper)
                       {
                        resIndic=-1.0;
                       }
                    }
                 }
              }
            return resIndic;
           }

         //BB_Surfeuse_go : returns 1 if the candle is surfing on the upper BB, -1 if surfing on the lower BB
         //if price < MA20 returns 0
         //option returns 1 or -1 according to the way of the candle
         //param : input Bollinger, shift, option way (1 to activate)
         //ex : BB_Surfeuse_go:20,1,1
         if(methode=="BB_Surfeuse_go")
           {
            if(ArraySize(resParam)==3)
              {
               resIndic=0.0;
               int shift=StrToInteger(resParam[1]);
               double valMain=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,0,0);
               double valUpper=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,1,shift);
               double valLower=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,2,shift);

               if(iClose(NULL,timeframe,shift)>valUpper && MarketInfo(symbol,MODE_BID)>valMain)
                 {
                  resIndic=1.0;
                 }
               if(iClose(NULL,timeframe,shift)<valLower && MarketInfo(symbol,MODE_BID)<valMain)
                 {
                  resIndic=-1.0;
                 }
               //option way
               if(resParam[2]=="1" && resIndic!=0.0)
                 {
                  if(resIndic==1.0 && MarketInfo(symbol,MODE_BID)<Open[0])
                    {
                     resIndic=0.0;
                    }
                  if(resIndic==-1.0 && MarketInfo(symbol,MODE_BID)>Open[0])
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }

         // TR_2_STD_go : returns 1 if true range is superior to 2 standard deviation and it's a up candle
         //returns -1 if true range is superior to 2 standard deviation and it's a down candle else returns 0
         //param : BB  avg, deviation, shift
         //ex : TR_2_STD_go:20,2,1
         if(methode=="TR_2_STD_go")
           {
            if(ArraySize(resParam)==3)
              {
               resIndic=0.0;
               int shift=StrToInteger(resParam[1]);
               double valMain=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,0,0);
               double valUpper=iBands(symbol,timeframe,StrToInteger(resParam[0]),2,0,PRICE_CLOSE,1,shift);
               double val2std=valUpper-valMain;
               double valTR=iHigh(NULL,timeframe,shift)-iLow(NULL,timeframe,shift);

               if(valTR>=val2std)
                 {
                  if(iClose(NULL,timeframe,shift)>iOpen(NULL,timeframe,shift))
                    {
                     resIndic= 1.0;
                    }
                  else
                    {
                     resIndic= -1.0;
                    }
                 }
              }

            return resIndic;
           }

         //CCI_val : returns the CCI value ex : 52.4
         //param : param CCI, shift
         //ex : CCI_val:14,1
         if(methode=="CCI_val")
           {
            if(ArraySize(resParam)==2)
              {
               resIndic=iCCI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]));
              }
            return resIndic;
           }

         //CCI_val_seuil : returns the CCI value relative to a threshold ex : -52.4
         //param : param CCI, shift, threshold
         //ex : CCI_val:20,1,200
         if(methode=="CCI_val_seuil")
           {
            if(ArraySize(resParam)==3)
              {
               double val=iCCI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,StrToInteger(resParam[1]));

               if(val>=0)
                 {
                  resIndic=val-StrToInteger(resParam[2]);
                 }
               else
                 {
                  resIndic=val+StrToInteger(resParam[2]);
                 }
              }
            return resIndic;
           }

         //CCI_retour_seuil : returns 1 if CCI passed above thresold during last n candles and returned below the threshold
         // returns -1.0 if CCI passed below thresholdsi during last n candles and returned above the threshold
         //else 0.0 ==> WARNING the 5th  input if set, inverts the result to spot entry and exit spots
         //param : param CCI, shift, threshold, nb candles to check, invert result (set to -1)
         //ex : CCI_retour_seuil:14,0,200,3,-1
         if(methode=="CCI_retour_seuil")
           {
            if(ArraySize(resParam)>=4)
              {
               int shift=StrToInteger(resParam[1]);
               int seuil=StrToInteger(resParam[2]);

               int inversion=1;
               if(ArraySize(resParam)==5)
                 {
                  inversion=StrToInteger(resParam[4]);
                 }

               double val=iCCI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,shift);
               resIndic=0.0;

               if(val<seuil && val>(-1*seuil))
                 {
                  for(int i=shift; i<=shift+StrToInteger(resParam[3])-1; i++)
                    {
                     double valprec=iCCI(symbol,timeframe,StrToInteger(resParam[0]),PRICE_CLOSE,shift+i);
                     if(valprec>=seuil)
                       {
                        resIndic=1.0*inversion;
                       }
                     else
                       {
                        if(valprec<=(-1*seuil))
                          {
                           resIndic=-1.0*inversion;
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         //Stoch_val : returns the value of a Stochastic line ex : 52.4
         //param :  period K Stoch,period  D, signal,line(0/1), shift
         //ex : Stoch_val:14,3,3,0,1
         if(methode=="Stoch_val")
           {
            if(ArraySize(resParam)==5)
              {
               resIndic=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,StrToInteger(resParam[3]),StrToInteger(resParam[4]));
              }
            return resIndic;
           }

         //Stoch_val_Signal : returns 1 if the stock main line is above the signal line else -1
         //param : period K Stoch,period  D, signal, shift
         //ex : Stoch_val_Signal:14,3,3,1
         if(methode=="Stoch_val_Signal")
           {
            if(ArraySize(resParam)==4)
              {
               double main=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,0,StrToInteger(resParam[4]));
               double signal=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,1,StrToInteger(resParam[4]));

               if(main>=signal)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // Stoch_val_Signal_Go : returns 1 if the main line is above the signal line since the last candle
         // returns -1.0 if the main line is below the signal line since the last candle  else 0 ex : 1.0
         //param : period K Stoch, Period D, signal, threshold, shift
         //ex : Stoch_val_Signal_Go:14,3,3,30,1
         if(methode=="Stoch_val_Signal_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int seuil=StrToInteger(resParam[3]);
               resIndic=0.0;

               double main=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,0,shift);
               double signal=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,1,shift);

               shift++;
               if(main>=signal && main<=50-seuil)
                 {
                  double main_prec=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,0,shift);
                  double signal_prec=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,1,shift);
                  if(main_prec<=signal_prec)
                    {
                     resIndic=1.0;
                    }
                 }
               else
                 {
                  if(main<=signal && main>=50+seuil)
                    {
                     double main_prec=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,0,shift);
                     double signal_prec=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,1,shift);
                     if(main_prec>=signal_prec)
                       {
                        resIndic=-1.0;
                       }
                    }
                 }
              }
            return resIndic;
           }

         //Stoch_pos_seuil : returns 1 if the choosen line is above 50+threshold or -1 if below 50-threshold otherwise 0
         //param : period K Stoch, period D, signal,line, shift, threshold
         //ex : Stoch_pos_seuil:14,3,3,0,1,30
         if(methode=="Stoch_pos_seuil")
           {
            if(ArraySize(resParam)==6)
              {
               double val=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,StrToInteger(resParam[3]),StrToInteger(resParam[4]));

               if(val>=50+StrToInteger(resParam[5]))
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  if(val<=50-StrToInteger(resParam[5]))
                    {
                     resIndic=-1.0;
                    }
                  else
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }

         //Stoch_retour_seuil : returns 1 if the stoch line passed above thresold during last n candles and returned below the threshold
         // returns -1 if the stoch line passed below thresold during last n candles and returned in the other way
         //else 0.0 ==> WARNING the 5th  input if set, inverts the result to spot entry and exit spots
         //param : period K Stoch, period D, signal,line, shift, threshold, nb candles to check, invert the result (set -1)
         //ex : Stoch_retour_seuil:14,3,3,0,1,30,3,-1
         if(methode=="Stoch_retour_seuil")
           {
            if(ArraySize(resParam)>=7)
              {
               int shift=StrToInteger(resParam[4]);
               int seuil=StrToInteger(resParam[5]);

               int inversion=1;
               if(ArraySize(resParam)==8)
                 {
                  inversion=StrToInteger(resParam[7]);
                 }

               double val=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,StrToInteger(resParam[3]),shift);
               resIndic=0.0;

               if(val<50+seuil && val>50-seuil)
                 {
                  for(int i=shift+1; i<=shift+StrToInteger(resParam[6]); i++)
                    {
                     double valprec=iStochastic(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),MODE_SMA,0,StrToInteger(resParam[3]),shift+i);
                     if(valprec>=50+seuil)
                       {
                        resIndic=1.0*inversion;
                       }
                     else
                       {
                        if(valprec<=50-seuil)
                          {
                           resIndic=-1.0*inversion;
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         //Phase_val : returns the BB phase (1,2,3 or 4)
         //param : period BB, std, threshold Phase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift, * direction (set -1)
         //ex : Phase_val:20,2,15,5,150,1,-1
         if(methode=="Phase_val")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";

               double sens=1.0;

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               if(ArraySize(resParam)==7)  // trend of the line
                 {
                  if(resParam[6]=="-1")
                    {
                     sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);
                    }
                 }
               resIndic=phase*sens;
              }
            return resIndic;
           }

         //Cycle_Vol_Seuil_Go : returns 1 if cycle volatility is above the threshold else 0
         //param : period BB, std, threshold, shift,value to return
         //ex : Cycle_Vol_Seuil_Go:20,2,20,1,1
         if(methode=="Cycle_Vol_Seuil_Go")
           {
            if(ArraySize(resParam)>=4) //15,5,150
              {
               int shift=StrToInteger(resParam[3]);
               int val=1;
               if(ArraySize(resParam)==5)
                 {
                  val=StrToInteger(resParam[4]);
                 }

               string monIndicPhase="cycle_vol";
               resIndic=0.0;

               double vol=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),2,shift);

               if(vol>=StrToInteger(resParam[2]))
                 {
                  resIndic=val;
                 }
              }
            return resIndic;
           }


         //Phase_4_1_val : returns the BB phase if it's a phase 1 or 4 else 0
         //param : period BB, std, Threshold Phase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1 shift, * direction (set -1), invert result (set -1), way (BUY or SELL)
         //ex : Phase_4_1_val:20,2,15,5,150,1,-1,-1,BUY
         if(methode=="Phase_4_1_val")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               double  direction=0.0,inversion=1.0,sensTmp=1.0,sens=1.0; // direction : 1 if BUY -1 if SELL
               string monIndicPhase="phases_BB_extralight";

               if(ArraySize(resParam)>=8)
                 {
                  inversion=StrToInteger(resParam[7]);
                 }
               if(ArraySize(resParam)==9)
                 {
                  if(resParam[7]=="BUY")
                    {
                     direction=1.0;
                    }
                  else
                    {
                     if(resParam[7]=="SELL")
                       {
                        direction=-1.0;
                       }
                    }
                 }

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               sensTmp=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);

               if(direction!=0.0 && sensTmp!=direction)
                 {
                  sens=sensTmp;
                  inversion=inversion*-1.0;
                 }
               else
                 {
                  if(phase==2.0 || phase==3.0)
                    {
                     sens=0.0;
                    }
                  else   // phase 4 or 1
                    {
                     if(ArraySize(resParam)>=7)  //if we want the direction
                       {
                        if(resParam[6]=="-1")
                          {
                           sens=sensTmp;
                          }
                       }
                    }
                 }
               resIndic=phase*sens*inversion;

              }
            return resIndic;
           }

         //Phase_4_1_go : returns 6666.0 (special value) if it's a BB phase 1 or 4 else 0
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift
         //ex : Phase_4_1_go:20,2,15,5,150,1
         if(methode=="Phase_4_1_go")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               resIndic=0.0;

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               if(phase==1.0 || phase==4.0)
                 {
                  resIndic=6666.0;
                 }
              }
            return resIndic;
           }

         //Phase_Sens_val : returns the trend of the BB phase : 1 for long -1 for short
         //param : period BB, Std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift
         //ex : Phase_Sens_val:20,2,15,5,150,1
         if(methode=="Phase_Sens_val")
           {
            if(ArraySize(resParam)==6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";

               double sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);

               resIndic=sens;
              }
            return resIndic;
           }

         //Phase_Surfeuse_val : returns the number of the current surfing candle, positive value if upper BB, negative if lower BB else (no surfing) 0
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1,SpreadMaxPhase1, shift
         //ex : Phase_Surfeuse_val:20,2,15,5,150,3,1
         if(methode=="Phase_Surfeuse_val")
           {
            if(ArraySize(resParam)==7)
              {
               int shift=StrToInteger(resParam[6]);
               string monIndicPhase="phases_BB_light";

               double surfeuse=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),0,StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[5]),StrToInteger(resParam[0])+StrToInteger(resParam[5]),6,shift);
               if(surfeuse==EMPTY_VALUE)
                 {
                  surfeuse=0.0;
                 }

               resIndic=surfeuse;
              }
            return resIndic;
           }


         //Phase_Autiste_go : returns if we are in BB phase 2 or 3, option with trend 1 for long -1 for short
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift,* direction (set -1)
         //ex : Phase_Autiste_go:20,2,15,5,150,1,-1
         if(methode=="Phase_Autiste_go")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               double sens=1.0;

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               if(ArraySize(resParam)==7 && phase>=2.0 && phase<=3.0)   // for the direction
                 {
                  if(resParam[6]=="-1")
                    {
                     sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);
                    }
                 }

               if(phase>=2.0 && phase<=3.0)
                 {
                  resIndic=sens;
                 }
               else
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         //Phase_2_en_cours : returns if we are in BB phase 2, option with trend 1 for long -1 for short
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift,* direction (set -1), default value (0 or 6666)
         //ex : Phase_2_en_cours:20,2,15,5,150,1,-1,6666
         if(methode=="Phase_2_en_cours")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               double sens=1.0,defaultValue=0.0;

               if(ArraySize(resParam)==8)
                 {
                  defaultValue=StrToInteger(resParam[7]);
                 }

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               if(phase==2.0)
                 {
                  if(ArraySize(resParam)>=7)
                    {
                     if(resParam[6]=="-1")
                       {
                        sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);
                       }
                    }
                  resIndic=sens;
                 }
               else
                 {
                  resIndic=defaultValue;
                 }
              }
            return resIndic;
           }

         //Phase_Autiste_P1_go : returns if we are in BB phase 1,2 or 3 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift,* direction (set -1), returned value for -1
         //ex : Phase_val:20,2,15,5,150,1,-1,-5555
         if(methode=="Phase_Autiste_P1_go")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               double sens=1.0,retPhase1=-5555.0;

               if(ArraySize(resParam)==8)
                 {
                  retPhase1=StrToDouble(resParam[7]);
                 }

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),5,shift);

               //si on veut avoir le sens en plus
               if(ArraySize(resParam)>=7 && phase>=1.0 && phase<=3.0)
                 {
                  if(resParam[6]=="-1")
                    {
                     sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),StrToInteger(resParam[0]),6,shift);
                    }
                 }

               if(phase>=2.0 && phase<=3.0)
                 {
                  resIndic=sens;
                 }
               else
                 {
                  if(phase==1.0)
                    {
                     resIndic=retPhase1;
                    }
                  else
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }

         //Phase_P1_P2_go : returns if we are in BB phase 1 or 2 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift,* direction (set -1), returned value for phase 1
         //ex : Phase_P1_P2_go:20,2,15,5,150,1,-1,-5555
         if(methode=="Phase_P1_P2_go")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               double sens=1.0,retPhase1=0.0;
               resIndic=0.0;

               if(ArraySize(resParam)==8)
                 {
                  retPhase1=StrToDouble(resParam[7]);
                 }

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),5,shift);

               if(ArraySize(resParam)>=7 && phase>=1.0 && phase<=2.0)  //for direction
                 {
                  if(resParam[6]=="-1")
                    {
                     sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),6,shift);
                    }
                 }
               if(phase==2.0 || (phase==1.0 && retPhase1==0.0))
                 {
                  resIndic=sens;
                 }
               else
                 {
                  if(phase==1.0)
                    {
                     resIndic=retPhase1;
                    }
                  else
                    {
                     resIndic=0.0;
                    }
                 }
              }
            return resIndic;
           }

         //Phase_2_go : returns if we are in BB phase 2 with option for the trned 1 for long -1 for short else 0 or -5555 if phase 1
         //option for phase 1, if option set to 1, returns1 only if the previous phase is 1
         //param : period BB, std, ThresholdPhase1,PerCent_ToleranceBBPhase1,PerCent_RatioET_TR_Phase1, shift,* direction (set -1),option phase 1
         //ex : Phase_2_go:20,2,15,5,150,1,-1,1
         if(methode=="Phase_2_go")
           {
            if(ArraySize(resParam)>=6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndicPhase="phases_BB_extralight";
               double sens=1.0;

               double phase=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),5,shift);
               //Print("Phase_2_go phase "+phase );
               if(phase==2.0)
                 {
                  double phase_prec=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),5,shift+1);

                  //phase 1 option
                  if(ArraySize(resParam)>=7)
                    {

                     if(resParam[6]=="-1") //for direction
                       {
                        sens=iCustom(symbol,timeframe,monIndicPhase,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),StrToInteger(resParam[3]),StrToInteger(resParam[4]),6,shift);
                       }

                     if(resParam[7]=="1" && phase_prec!=1.0) //only previous phase 1
                       {
                        sens=0.0;
                       }

                     resIndic=sens;
                    }
                  else
                    {
                     resIndic=sens;
                    }

                 }
               else
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         //Ichimoku_line_price : returns value of an ichimoku  line
         //value for the line : tenkan, kijun, chikou, SSA, SSB
         //param : Tenkan, Kijun, Senkou, line, shift
         //ex : Ichimoku_line_price_dif:9,26,52,Tenkan,0
         if(methode=="Ichimoku_line_price")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int line=0;
               string monIndicIchi="Ichimoku";
               StringToLower(resParam[2]);
               StringToLower(resParam[3]);

               if(resParam[3]=="tenkan")
                 {
                  line=MODE_TENKANSEN;
                 }
               if(resParam[3]=="kijun")
                 {
                  line=MODE_KIJUNSEN;
                 }
               if(resParam[3]=="chikou")
                 {
                  line= MODE_CHIKOUSPAN;
                 }
               if(resParam[3]=="ssa")
                 {
                  line=MODE_SENKOUSPANA;
                 }
               if(resParam[3]=="ssb")
                 {
                  line= MODE_SENKOUSPANB;
                 }

               resIndic= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),line,shift);
              }
            return resIndic;
           }

         //Ichimoku_line_price_dif : returns the difference between a ichimoku line and the price
         // nagative value if price is below
         //valeur for the line : tenkan, kijun, chikou, SSA, SSB
         //param : Tenkan, Kijun, Senkou, line, shift
         //ex : Ichimoku_line_price_dif:9,26,52,Tenkan,0
         if(methode=="Ichimoku_line_price_dif")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int line=0;
               string monIndicIchi="Ichimoku";
               StringToLower(resParam[2]);
               StringToLower(resParam[3]);

               if(resParam[3]=="tenkan")
                 {
                  line=MODE_TENKANSEN;
                 }
               if(resParam[3]=="kijun")
                 {
                  line=MODE_KIJUNSEN;
                 }
               if(resParam[3]=="chikou")
                 {
                  line= MODE_CHIKOUSPAN;
                 }
               if(resParam[3]=="ssa")
                 {
                  line=MODE_SENKOUSPANA;
                 }
               if(resParam[3]=="ssb")
                 {
                  line= MODE_SENKOUSPANB;
                 }

               double val= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),line,shift);
               resIndic=MarketInfo(symbol,MODE_BID)-val;
              }
            return resIndic;
           }

         //Ichimoku_line_go : returns 1 if the price just crossed the ichimoku line up way during the last n bars
         // returns -1 if the price just crossed the ichimoku line down way else 0
         //line values : tenkan, kijun, chikou, SSA, SSB
         //param : Tenkan, Kijun, Senkou, line selected,nb bars watched, shift
         //ex : Ichimoku_line_go:9,26,52,Tenkan,1,1
         if(methode=="Ichimoku_line_go")
           {
            if(ArraySize(resParam)==6)
              {
               int shift=StrToInteger(resParam[5]);
               int line=0;
               int nbbars=StrToInteger(resParam[4]);
               string monIndicIchi="Ichimoku",direction="",dir_prec="";
               bool cross=false;

               StringToLower(resParam[3]);
               if(resParam[4]=="tenkan")
                 {
                  line=MODE_TENKANSEN;
                 }
               if(resParam[4]=="kijun")
                 {
                  line=MODE_KIJUNSEN;
                 }
               if(resParam[4]=="chikou")
                 {
                  line= MODE_CHIKOUSPAN;
                 }
               if(resParam[4]=="ssa")
                 {
                  line=MODE_SENKOUSPANA;
                 }
               if(resParam[4]=="ssb")
                 {
                  line= MODE_SENKOUSPANB;
                 }

               double val= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),line,shift);

               if(iClose(NULL,timeframe,shift)-val>0)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),line,i);

                  if(val_prec>iClose(NULL,timeframe,i))
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }

                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // Kijun_Tenkan_Direction : returns 1 if the price > Tenkan  >= Kijun returns -1 if the prix < Kijun <= Tenkan else 0
         ///param : Tenkan, Kijun, Senkou, shift
         //ex : Kijun_Tenkan_Go:9,26,52,0
         if(methode=="Kijun_Tenkan_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               resIndic=0.0;

               double Tenkan= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_TENKANSEN,shift);
               double Kijun= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_KIJUNSEN,shift);

               if(MarketInfo(symbol,MODE_BID)>Tenkan && Tenkan>=Kijun)
                 {
                  resIndic=1.0;
                 }
               if(MarketInfo(symbol,MODE_BID)<Tenkan && Tenkan<=Kijun)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //Ichimoku_Alignment : returns 1 if selected lines are aligned in a bull way
         //returns -1 if selected lines are aligned in a bear way eles 0, option to inverse result
         //lignes are BID, TENKAN, KIJUN, SSA,SSB,CHIKOU,KUMO
         //param : Tenkan, Kijun, Senkou, list of lines,shift,inversion
         //ex : Ichimoku_Alignment:9,26,52,BID-TENKAN-KIJUN,0,1
         if(methode=="Ichimoku_Alignment")
           {
            int inversion=1;
            if(ArraySize(resParam)>=5)
              {
               int shift=StrToInteger(resParam[4]);
               bool hasBid=false,hasTenkan=false,hasKijun=false,hasSSA=false,hasSSB=false,hasChikou=false,hasKumo=false;
               string listLines[],monIndicIchi="Ichimoku";
               double monBid=0,monBidChikou=0,Tenkan=0,Kijun=0,SSA=0,SSB=0,Chikou=0;
               resIndic=0.0;

               if(ArraySize(resParam)==6)
                 {
                  inversion=StrToInteger(resParam[5]);
                 }

               if(StringSplit(resParam[3],StringGetCharacter("-",0),listLines)>=2)
                 {
                  for(int i=0; i<ArraySize(listLines); i++)
                    {
                     if(listLines[i]=="BID")
                       {
                        hasBid=true;
                       }
                     if(listLines[i]=="TENKAN")
                       {
                        hasTenkan=true;
                       }
                     if(listLines[i]=="KIJUN")
                       {
                        hasKijun=true;
                       }
                     if(listLines[i]=="SSA")
                       {
                        hasSSA=true;
                       }
                     if(listLines[i]=="SSB")
                       {
                        hasSSB=true;
                       }
                     if(listLines[i]=="CHIKOU")
                       {
                        hasChikou=true;
                       }
                     if(listLines[i]=="KUMO")
                       {
                        hasKumo=true;
                       }
                    }

                  if(hasKumo)
                    {
                     hasSSA=true;
                     hasSSB=true;
                    }

                  if(hasBid)
                    {
                     monBid=iClose(NULL,timeframe,shift);
                    }
                  if(hasTenkan)
                    {
                     Tenkan= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_TENKANSEN,shift);
                    }
                  else
                    {
                     Tenkan=monBid;
                    }
                  if(hasKijun)
                    {
                     Kijun= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_KIJUNSEN,shift);
                    }
                  else
                    {
                     Kijun=Tenkan;
                    }
                  if(hasSSA)
                    {
                     SSA= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_SENKOUSPANA,shift);
                    }
                  else
                    {
                     SSA=Kijun;
                    }
                  if(hasSSB)
                    {
                     SSB= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_SENKOUSPANB,shift);
                    }
                  else
                    {
                     SSB=SSA;
                    }
                  if(hasChikou)
                    {
                     Chikou= iIchimoku(symbol,timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToInteger(resParam[2]),MODE_CHIKOUSPAN,shift+26);
                     monBidChikou=iClose(NULL,timeframe,shift+26);
                    }
                  else
                    {
                     Chikou=monBidChikou;
                    }

                  if(hasKumo)
                    {
                     if((monBid>=Tenkan || monBid==0) && (Tenkan>=Kijun || Tenkan==0)  && Kijun>=SSA && Kijun>=SSB && monBidChikou<=Chikou)
                       {
                        resIndic=1.0;
                       }
                     if((monBid<=Tenkan || monBid==0) && (Tenkan<=Kijun || Tenkan==0) && Kijun<=SSA && Kijun<=SSB && monBidChikou>=Chikou)
                       {
                        resIndic=-1.0;
                       }
                    }
                  else
                    {
                     if((monBid>=Tenkan || monBid==0) && (Tenkan>=Kijun || Tenkan==0) && (Kijun>=SSA || Kijun==0) && SSA>=SSB && monBidChikou<=Chikou)
                       {
                        resIndic=1.0;
                       }
                     if((monBid<=Tenkan || monBid==0) && (Tenkan<=Kijun || Tenkan==0) && (Kijun<=SSA || Kijun==0) && SSA<=SSB && monBidChikou>=Chikou)
                       {
                        resIndic=-1.0;
                       }
                    }
                 }
              }
            return resIndic*inversion;
           }

         // Ichimoku_Alignment_Go : returns 1 if selected lines became aligned in a bull way in last n bars
         //returns -1 if selected lines became aligned in a bear way eles 0
         //lines are BID, TENKAN, KIJUN, SSA,SSB,CHIKOU,KUMO
         //param : Tenkan, Kijun, Senkou, list of lines,nb bars,shift,
         //ex : Ichimoku_Alignment_Go:9,26,52,BID-TENKAN-KIJUN,1,0
         if(methode=="Ichimoku_Alignment_Go")
           {
            if(ArraySize(resParam)==6)
              {
               int shift=StrToInteger(resParam[5]);
               resIndic=0.0;
               string direction="", direction_deb="";
               string aligCall="Ichimoku_Alignment:"+resParam[0]+","+resParam[1]+","+resParam[2]+","+resParam[3]+",";
               bool cross=false;

               int alig=getIndicatorFromParam(symbol, timeframe,aligCall+shift,handle);

               if(alig!=0)
                 {
                  int i=shift+1;
                  while(i<=shift+StrToInteger(resParam[4]) && !cross)
                    {
                     int alig_bef=getIndicatorFromParam(symbol, timeframe,aligCall+i,handle);
                     if((alig==1 && alig_bef<=0) || (alig==-1 && alig_bef>=0))
                       {
                        resIndic=alig;
                        cross=true;
                       }
                     i++;
                    }
                 }

              }

            return resIndic;
           }

         //Aroon_Go : returns 1 if Aroon lines crossed up direction during the last n candles
         // -1 if crossed down direction, 0 default
         //param : Param Aroon, nb candles passed,shift
         //ex : Aroon_Go:14,7,1
         if(methode=="Aroon_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               resIndic=0.0;
               string monIndic="Aroon", sens="",sens_prec="";
               bool croisement=false;

               double Aroon_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               double Aroon_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               if(Aroon_Up>Aroon_Down)
                 {
                  sens="UP";
                 }
               else
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+StrToInteger(resParam[1]) && !croisement)
                 {
                  double Aroon_Up_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,i);
                  double Aroon_Down_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,i);

                  if(Aroon_Up_prec>Aroon_Down_prec)
                    {
                     sens_prec="UP";
                    }
                  else
                    {
                     sens_prec="DOWN";
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     croisement=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        croisement=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         //Aroon_Direction : returns 1 if Aroon is up  else -1
         //param : Param Aroon, shift
         //ex : Aroon_Direction:14,1
         if(methode=="Aroon_Direction")
           {
            if(ArraySize(resParam)==2)
              {
               int shift=StrToInteger(resParam[1]);
               resIndic=0.0;
               string monIndic="Aroon";

               double Aroon_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               double Aroon_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               if(Aroon_Up>Aroon_Down)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //Aroon_Go_Seuil : returns 1 if the Aroon bull line >= threshold during last n candles
         // -1 if bear line >= threshold, 0 default
         //param : Param Aroon, nb candles passed, threshold, shift
         //ex : Aroon_Go_Seuil:14,7,100,1
         if(methode=="Aroon_Go_Seuil")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               int seuil=StrToInteger(resParam[2]);
               int arrParam=StrToInteger(resParam[0]);
               resIndic=0.0;
               string monIndic="Aroon", sens="",sens_prec="", APICheckCross="Aroon_Go:"+arrParam+","+resParam[1]+","+shift;
               bool sortie=false;

               double sensCross=getIndicatorFromParam(symbol,  timeframe,APICheckCross,handle);

               double Aroon_Up =iCustom(symbol,timeframe,monIndic,arrParam,0,shift);
               double Aroon_Down =iCustom(symbol,timeframe,monIndic,arrParam,1,shift);
               if(Aroon_Up>=seuil)
                 {
                  sens="UP";
                 }
               else
                 {
                  if(Aroon_Down>=seuil)
                    {
                     sens="DOWN";
                    }
                  else
                    {
                     sens="NO";
                    }
                 }

               if(sens=="NO")
                 {
                  int i=shift+1;
                  while(i<=shift+StrToInteger(resParam[1]) && sens=="NO")
                    {
                     double Aroon_Up_prec=iCustom(symbol,timeframe,monIndic,arrParam,0,i);
                     double Aroon_Down_prec=iCustom(symbol,timeframe,monIndic,arrParam,1,i);

                     if(Aroon_Up_prec>=seuil)
                       {
                        sens="UP";
                       }
                     else
                       {
                        if(Aroon_Down_prec>=seuil)
                          {
                           sens="DOWN";
                          }
                        else
                          {
                           sens="NO";
                          }
                       }

                     i++;
                    }
                 }
               if(sens=="UP" && sensCross>0)
                 {
                  resIndic=1.0;
                 }
               if(sens=="DOWN" && sensCross<0)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // Aroon_Direction_Seuil : returns 1 if Aroon's bull line is above threshold,
         // -1 if Aroon's bear line is above threshold else 0
         //param : Param Aroon, threshold, shift
         //ex : Aroon_Direction_Seuil:14,100,1
         if(methode=="Aroon_Direction_Seuil")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               int threshold=StrToInteger(resParam[1]);
               resIndic=0.0;
               string monIndic="Aroon";

               double Aroon_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               double Aroon_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);

               if(Aroon_Up>=threshold)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  if(Aroon_Down>=threshold)
                    {
                     resIndic=-1.0;
                    }
                 }
              }
            return resIndic;
           }

         //RVI_Go : returns 1 if RVI > Signal+margin, -1 if RVI < signal- margin else 0
         //param : input RVI, margin,nb candles,shift
         //ex : RVI_Go:8,0.02,7,1
         if(methode=="RVI_Go")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               double marge=StrToDouble(resParam[1]);
               int nbbars=StrToInteger(resParam[2]);
               string sens="NEUTRAL",sens_prec="NEUTRAL";
               resIndic=0.0;
               bool cross=false;

               double RVI =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_MAIN,shift);
               double signal =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_SIGNAL,shift);

               if(RVI-signal>marge)
                 {
                  sens="UP";
                 }
               if(signal-RVI>marge)
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double RVI_prec =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_MAIN,i);
                  double signal_prec =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_SIGNAL,i);

                  if(RVI_prec-signal_prec>marge)
                    {
                     sens_prec="UP";
                     if(sens=="NEUTRAL")
                       {
                        sens="UP";
                       }
                    }
                  if(signal_prec-RVI_prec>marge)
                    {
                     sens_prec="DOWN";
                     if(sens=="NEUTRAL")
                       {
                        sens="DOWN";
                       }
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         //RVI_Direction : returns 1 if RVI > Signal+margin, -1 if RVI < signal- margin else 0
         //param : input RVI, margin,shift
         //ex : RVI_Direction:8,0.02,1
         if(methode=="RVI_Direction")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               double marge=StrToDouble(resParam[1]);
               resIndic=0.0;

               double RVI =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_MAIN,shift);
               double signal =iRVI(symbol,timeframe,StrToInteger(resParam[0]),MODE_SIGNAL,shift);

               if(RVI-signal>marge)
                 {
                  resIndic=1.0;
                 }
               if(signal-RVI>marge)
                 {
                  resIndic=-1.0;
                 }

              }
            return resIndic;
           }

         //REX_Go : returns 1 if REX > Signal+margin, -1 if REX < signal- margin else 0
         //param : input REX, signal REX,method  REX (0 SMA, 1, EMA, 2 SMMA, 3 LWMA), margin,shift
         //ex : REX_Go:14,14,0,20,1
         if(methode=="REX_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               double marge=StrToDouble(resParam[3]);
               string monIndic="Rex";
               resIndic=0.0;

               double REX =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[2]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),0,shift);
               double signal =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[2]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),1,shift);

               if(REX-signal>marge)
                 {
                  resIndic=1.0;
                 }
               if(signal-REX>marge)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //Cassure_Go : returns 1 if price > highest of last n candles, -1 if price < lowest of last n candles else 0
         //modes : CLOSE : check close of n candles, HL : check high low
         //if shift = 0 check actual price if shift =1 check last candle
         //param : mode, nb candles,shift
         //ex : Cassure_Go:HL,12,1
         if(methode=="Cassure_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]),val_index_high,val_index_low;
               double nb_candles=StrToDouble(resParam[1]),val_high,val_low;
               resIndic=0.0;
               string monIndic="Lignes_hauts_bas";

               if(resParam[0]=="CLOSE")
                 {
                  val_index_high=iHighest(symbol,timeframe,MODE_CLOSE,nb_candles,shift);
                  val_index_low=iLowest(symbol,timeframe,MODE_CLOSE,nb_candles,shift);
                  if(val_index_high!=-1 && val_index_low!=-1)
                    {
                     val_high=Close[val_index_high];
                     val_low=Close[val_index_low];
                    }
                 }
               else
                 {

                  if(resParam[0]=="HL")
                    {
                     val_high =iCustom(symbol,timeframe,monIndic,nb_candles,nb_candles,nb_candles,0,3,shift+1);
                     val_low =iCustom(symbol,timeframe,monIndic,nb_candles,nb_candles,nb_candles,0,3,shift+1);
                    }
                 }

               if(shift==0)
                 {
                  if(MarketInfo(symbol,MODE_BID)>val_high)
                    {
                     resIndic=1.0;
                    }
                  if(MarketInfo(symbol,MODE_BID)<val_low)
                    {
                     resIndic=-1.0;
                    }
                 }
               else
                 {
                  if(iClose(symbol,timeframe,shift)>val_high)
                    {
                     resIndic=1.0;
                    }
                  if(iClose(symbol,timeframe,shift)<val_low)
                    {
                     resIndic=-1.0;
                    }
                 }
              }
            return resIndic;
           }

         // Point_Pivot_Forex_Sens : returns 1 if price > open(W1,0) and > close(W1,1), -1 if price < open(W1,0) and < close(W1,1) else 0
         //ex : Point_Pivot_Forex_Sens
         if(methode=="Point_Pivot_Forex_Sens")
           {

            resIndic=0.0;

            if(MarketInfo(symbol,MODE_BID)>iClose(symbol,timeframe,1) && MarketInfo(symbol,MODE_BID)>iOpen(symbol,timeframe,0))
              {  resIndic=1.0; }

            if(MarketInfo(symbol,MODE_BID)<iClose(symbol,timeframe,1) && MarketInfo(symbol,MODE_BID)<iOpen(symbol,timeframe,0))
              {  resIndic=-1.0; }
            return resIndic;
           }

         // Point_Pivot_Index_Sens : returns 1 if price > open and close
         // returns -1 if price < open and close else 0
         // inputs : time of the start break, time of the end of the break
         //ex : Point_Pivot_Index_Sens:1830,1000
         if(methode=="Point_Pivot_Index_Sens")
           {
            //à finir
            if(ArraySize(resParam)>=1)
              {
               resIndic=0.0;

               double bidNow=MarketInfo(symbol,MODE_BID);
               double priceStart=getOpenPriceGivenTime(symbol, resParam[0], false,handle);
               double priceEnd=0.0;

               if(ArraySize(resParam)==2)
                 {
                  priceEnd=getOpenPriceGivenTime(symbol, resParam[1], true,handle);
                  if(bidNow>priceStart && bidNow>priceEnd)
                    {
                     resIndic=1.0;
                    }
                  if(bidNow<priceStart && bidNow<priceEnd)
                    {
                     resIndic=-1.0;
                    }

                 }
               else
                 {
                  if(bidNow>priceStart)
                    {
                     resIndic=1.0;
                    }
                  if(bidNow<priceStart)
                    {
                     resIndic=-1.0;
                    }
                 }
              }
            return resIndic;
           }

         //BullsVsBears_Go : returns 1 if Bulls and Bears+marge crossed in bulls way during last N candles
         // returns -1 if they crossed bears waydurint last N candles
         //param : Param Bulls VS Bears, marge, N last candles, shift
         //ex : BullsVsBears_Go:14,0.01,7,1
         if(methode=="BullsVsBears_Go")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               double marge=StrToDouble(resParam[1]);
               string monIndic="bulls-vs-bears",sens="NEUTRAL",sens_prec="NEUTRAL";
               bool croisement=false;
               resIndic=0.0;

               double bulls =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               double bears =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);

               if(bulls-bears>marge)
                 {
                  sens="UP";
                 }
               if(bears-bulls>marge)
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+StrToInteger(resParam[2]) && !croisement)
                 {
                  double bulls_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,i);
                  double bears_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,i);

                  if(bulls_prec-bears_prec>marge)
                    {
                     sens_prec="UP";
                     if(sens=="NEUTRAL")
                       {
                        sens="UP";
                       }
                    }
                  if(bears_prec-bulls_prec>marge)
                    {
                     sens_prec="DOWN";
                     if(sens=="NEUTRAL")
                       {
                        sens="DOWN";
                       }
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     croisement=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        croisement=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         //BullsVsBears_Direction : returns 1 if Bulls and Bears+marge is in bulls way else -1
         //param : Param Bulls VS Bears, margin, shift
         //ex : BullsVsBears_Direction:14,0.01,1
         if(methode=="BullsVsBears_Direction")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               double marge=StrToDouble(resParam[1]);
               string monIndic="bulls-vs-bears";
               resIndic=0.0;

               double bulls =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               double bears =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);

               if(bulls-bears>marge)
                 {
                  resIndic=1.0;
                 }
               if(bears-bulls>marge)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //ASH_Go : returns 1 if ASH lines+marge crossed in bulls way during last N candles
         //reSturns -1 if ASH lines+marge crossed in bears way during last N candles
         //param : Param ASH Mode,length,smooth,modeMA, margin,N last candles, shift
         //ex : ASH_Go:1,9,1,3,0.01,7,1
         if(methode=="ASH_Go")
           {
            if(ArraySize(resParam)==7)
              {
               int shift=StrToInteger(resParam[6]);
               double marge=StrToDouble(resParam[4]);
               string monIndic="absolute-strength-histogram",sens="NEUTRAL",sens_prec="NEUTRAL";
               bool croisement=false;
               resIndic=0.0;

               double bulls =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,2,shift);
               double bears =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,3,shift);

               if(bulls-bears>marge)
                 {
                  sens="UP";
                 }
               if(bears-bulls>marge)
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+StrToInteger(resParam[5]) && !croisement)
                 {
                  double bulls_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,2,i);
                  double bears_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,3,i);

                  if(bulls_prec-bears_prec>marge)
                    {
                     sens_prec="UP";
                     if(sens=="NEUTRAL")
                       {
                        sens="UP";
                       }
                    }
                  if(bears_prec-bulls_prec>marge)
                    {
                     sens_prec="DOWN";
                     if(sens=="NEUTRAL")
                       {
                        sens="DOWN";
                       }
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     croisement=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        croisement=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         //ASH_Direction : returns 1 if ASH lines+marge is in bulls side else returns -1
         //param : Param Bulls VS Bears Mode,length,smooth,modeMA, margin, shift
         //ex : ASH_Direction:1,9,1,3,0.01,1
         if(methode=="ASH_Direction")
           {
            if(ArraySize(resParam)==6)
              {
               int shift=StrToInteger(resParam[5]);
               double marge=StrToDouble(resParam[4]);
               string monIndic="absolute-strength-histogram";
               resIndic=0.0;

               double bulls =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,2,shift);
               double bears =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),4,0,StrToInteger(resParam[3]),3,3,shift);

               if(bulls-bears>marge)
                 {
                  resIndic=1.0;
                 }
               if(bears-bulls>marge)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //SSL_Channel_Go : returns 1 if SSL lines crossed in a bull trend during the last n candles
         // -1 if crossed in a bear way, 0 default
         //param : Param SSL, nb candles passées,shift
         //ex : SSL_Channel_Go:10,7,1
         if(methode=="SSL_Channel_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               resIndic=0.0;

               string monIndic="ssl-channel-chart-alert-indicator", sens="",sens_prec="";
               bool croisement=false;

               double SSL_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               double SSL_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               if(SSL_Up>SSL_Down)
                 {
                  sens="UP";
                 }
               else
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+StrToInteger(resParam[1]) && !croisement)
                 {
                  double SSL_Up_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,i);
                  double SSL_Down_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,i);

                  if(SSL_Up_prec>SSL_Down_prec)
                    {
                     sens_prec="UP";
                    }
                  else
                    {
                     sens_prec="DOWN";
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     croisement=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        croisement=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         //SSL_Channel_Direction : returns 1 if SSL Up line is above down line else returns -1
         //param : Param SSL, shift
         //ex : SSL_Channel_Direction:10,1
         if(methode=="SSL_Channel_Direction")
           {
            if(ArraySize(resParam)==2)
              {
               int shift=StrToInteger(resParam[1]);
               resIndic=0.0;

               string monIndic="ssl-channel-chart-alert-indicator", sens="",sens_prec="";

               double SSL_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);
               double SSL_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               if(SSL_Up>SSL_Down)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // Distance_BL_Go : returns 1 if price - base line is less than N ATR (NNFX system)
         // -1 if base line - price is less than N ATR, 0 by default
         //param : Base line param, ATR timeframe, ATR param, ATR coef
         //List of Base line param : MMS$period#shift -- KIJUN$shift -- TENKAN$shift  -- ALMA$period#shift -- KAUFMAN$periodAMA#nfast#v#G#dK#shift
         // -- MME$period#shift -- SSL$period#shift -- -- KAMA$periodKAMA#periodfast#periodslow#shift
         //ex : Distance_BL_Go:MMS$20#0,1440,14,1
         if(methode=="Distance_BL_Go")
           {
            if(ArraySize(resParam)==4)
              {
               resIndic=0.0;
               string monIndic="", sens="",sens_prec="";
               string myBLIndic[],myBLParam[];
               double myBLVal=0.0, myATR=0.0;

               //baseline calcul
               if(StringSplit(resParam[0],StringGetCharacter("$",0),myBLIndic)==2)
                 {
                  monIndic=myBLIndic[0];
                  if(StringSplit(myBLIndic[1],StringGetCharacter("#",0),myBLParam)>0)
                    {
                     if(monIndic=="MMS")
                       {
                        myBLVal=iMA(symbol,timeframe,StrToInteger(myBLParam[0]),0,MODE_SMA,PRICE_CLOSE,StrToInteger(myBLParam[1]));
                       }

                     if(monIndic=="MME")
                       {
                        myBLVal=iMA(symbol,timeframe,StrToInteger(myBLParam[0]),0,MODE_EMA,PRICE_CLOSE,StrToInteger(myBLParam[1]));
                       }

                     if(monIndic=="KIJUN")
                       {
                        myBLVal=iIchimoku(symbol,timeframe,9,26,52,MODE_KIJUNSEN,StrToInteger(myBLParam[0]));
                       }

                     if(monIndic=="TENKAN")
                       {
                        myBLVal=iIchimoku(symbol,timeframe,9,26,52,MODE_TENKANSEN,StrToInteger(myBLParam[0]));
                       }

                     if(monIndic=="ALMA")
                       {
                        myBLVal=getDefaultALMA(symbol,timeframe,StrToInteger(myBLParam[0]),0,StrToInteger(myBLParam[1]),handle);
                       }

                     if(monIndic=="DEMA")
                       {
                        myBLVal=iCustom(symbol,timeframe,"DEMA",StrToInteger(myBLParam[0]),0,StrToInteger(myBLParam[1]));
                       }

                     if(monIndic=="KAUFMAN")
                       {
                        myBLVal=iCustom(symbol,timeframe,"KAMA",StrToInteger(myBLParam[0]),StrToDouble(myBLParam[1]),StrToDouble(myBLParam[2]),0,StrToInteger(myBLParam[5]));  //
                       }

                     if(monIndic=="SSL")
                       {
                        myBLVal=iCustom(symbol,timeframe,"ssl-channel-chart-alert-indicator",StrToInteger(myBLParam[0]),0,StrToInteger(myBLParam[1]));
                       }

                     if(monIndic=="KAMA")
                       {
                        myBLVal=iCustom(symbol,timeframe,"KAMA",StrToInteger(myBLParam[0]),StrToDouble(myBLParam[1]),StrToDouble(myBLParam[2]),0,StrToInteger(myBLParam[3]));
                       }
                    }
                  else
                    {
                     logMe(handle,9,"Distance_BL_Go indicator without parameter !!!!!  ",1);
                    }
                 }
               else
                 {
                  logMe(handle,9,"Distance_BL_Go no indicator  !!!!!  ",1);
                 }

               if(myBLVal==0.0)
                 {
                  logMe(handle,9,"Distance_BL_Go Base line value 0.0  !!!!!  ",1);
                 }

               myATR=iATR(symbol,StrToInteger(resParam[1]),StrToInteger(resParam[2]),1);

               if(MarketInfo(symbol,MODE_ASK)>myBLVal && MarketInfo(symbol,MODE_ASK)-myBLVal<=myATR*StrToDouble(resParam[3]))
                 {
                  resIndic=1.0;
                 }
               if(MarketInfo(symbol,MODE_BID)<myBLVal && myBLVal-MarketInfo(symbol,MODE_BID)<=myATR*StrToDouble(resParam[3]))
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         //WAE_En_Cours : returns 1 if WAE is green bar above his line or if it's red abd above his line else 0
         //Short mode  : set at -1 to get -1 when red bar above his line, default 1
         //param : Senstive, ExplosionPower,TrendPower, Shift, Short mode
         //ex : WAE_En_Cours:150,15,15,0,1
         if(methode=="WAE_En_Cours")
           {
            if(ArraySize(resParam)>=3)
              {
               int shift=0,deadZonePip=30, negMode=1;

               if(ArraySize(resParam)>=4)
                 {
                  shift=StrToInteger(resParam[3]);
                  if(ArraySize(resParam)==5)
                    {
                     negMode=StrToInteger(resParam[4]);
                    }
                 }

               resIndic=0.0;

               string monIndic="Waddah_Attar_Explosion", sens="";

               double WAE_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,0,shift);
               double WAE_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,1,shift);
               double WAE_Line=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,2,shift);

               if(WAE_Up>WAE_Line)
                 {
                  resIndic=1.0;
                 }

               if(WAE_Down>WAE_Line)
                 {
                  resIndic=1.0*negMode;
                 }

              }
            return resIndic;
           }

         //WAE_Go : mode 1 returns val if WAE line is above treshold else 0,
         // mode 2 returns val if WAE bar is above treshold else 0,
         // mode 3 returns val if WAE bar or line is above treshold else 0,
         //param : Senstive, ExplosionPower,TrendPower,mode,  treshold,Shift, Value
         //ex : WAE_Go:150,15,15,2,0.02,0,1
         if(methode=="WAE_Go")
           {
            if(ArraySize(resParam)>=5)
              {
               int shift=0,deadZonePip=30, val=1,mode=StrToInteger(resParam[3]);
               double treshold=StrToDouble(resParam[4]), WAE_Up=0.0,WAE_Down=0.0,WAE_Line=0.0;
               string monIndic="Waddah_Attar_Explosion", sens="";

               if(ArraySize(resParam)>=5)
                 {
                  shift=StrToInteger(resParam[5]);
                 }
               if(ArraySize(resParam)==6)
                 {
                  val=StrToInteger(resParam[6]);
                 }

               if(mode>=1 && mode<=3)
                 {
                  resIndic=0.0;
                 }

               if(mode==1)
                 {
                  WAE_Line=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,2,shift);
                  if(WAE_Line>=treshold)
                    {
                     resIndic=1.0;
                    }
                 }
               else
                 {
                  if(mode==2)
                    {
                     WAE_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,0,shift);
                     WAE_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,1,shift);
                     if(WAE_Up>=treshold || WAE_Down>=treshold)
                       {
                        resIndic=1.0;
                       }
                    }
                  else
                    {
                     if(mode==3)
                       {
                        WAE_Line=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,2,shift);
                        WAE_Up =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,0,shift);
                        WAE_Down =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),deadZonePip,StrToInteger(resParam[1]),StrToInteger(resParam[2]),false,500,false,false,false,false,1,shift);
                        if(WAE_Up>=treshold || WAE_Down>=treshold || WAE_Line>=treshold)
                          {
                           resIndic=1.0;
                          }
                       }
                    }
                 }
              }
            return resIndic;
           }

         //ALMA_Direction : returns the direction of ALMA : -1/ 1
         //param : windowSize, shift
         //ex : ALMA_Direction:9,1
         if(methode=="ALMA_Direction")
           {
            if(ArraySize(resParam)==2)
              {
               int shift=StrToInteger(resParam[1]);
               double val=getDefaultALMA(symbol,timeframe,StrToInteger(resParam[0]),0,shift,handle);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // ALMA_Go : returns 1 if price crossed the ALMA line in last N bars in bull way
         // returns -1 if price crossed the ALMA line in last N bars in bear way
         //param : windowSize, N bars, shift
         //ex : ALMA_Go:9,7,1
         if(methode=="ALMA_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               int nbbars=StrToInteger(resParam[1]);
               string direction="",dir_prec="";
               bool cross=false;

               double val =getDefaultALMA(symbol,timeframe,StrToInteger(resParam[0]),0,shift,handle);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }
               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec =getDefaultALMA(symbol,timeframe,StrToInteger(resParam[0]),0,i,handle);

                  if(val_prec>iClose(NULL,timeframe,i))
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }

              }
            return resIndic;
           }

         // Kaufman_Direction : returns the direction of Kaufman : -1/ 1
         //param : periodAMA,nfast,v,G,dK, shift
         //ex : Kaufman_Direction:9,2,30,2.0,2.0,1
         if(methode=="Kaufman_Direction")
           {
            if(ArraySize(resParam)==6)
              {
               int shift=StrToInteger(resParam[5]);
               string monIndic="KAMA";//"kaufman";
               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
               logMe(handle,9,"Kauf_Direction val :"+ val+" resIndic : "+resIndic,1);
              }
            return resIndic;
           }

         // Kaufman_Go : returns 1 if price crossed the Kaufman line in last N bars in bull way
         // returns -1 if price crossed the Kaufman line in last N bars in bear way
         //param : periodAMA,nfast,v,G,dK,N bars, shift
         //ex : Kaufman_Direction:9,2,30,2.0,2.0,7,1
         if(methode=="Kaufman_Go")
           {
            if(ArraySize(resParam)==7)
              {
               int shift=StrToInteger(resParam[6]);
               int nbbars=StrToInteger(resParam[5]);
               string monIndic="KAMA";//"kaufman";
               string direction="",dir_prec="";
               bool cross=false;

               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,i);

                  if(val_prec>iClose(NULL,timeframe,i))
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // Vortex_Go : returns 1 if Plus and Minus+marge crossed in bulls way during last N candles
         // returns -1 if they crossed bears way durint last N candles
         //param : Param Vortex, marge, N last candles, shift
         //ex : Vortex_Go:14,0.01,7,1
         if(methode=="Vortex_Go")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               double marge=StrToDouble(resParam[1]);
               string monIndic="Vortex_Indicator",sens="NEUTRAL",sens_prec="NEUTRAL";
               bool croisement=false;
               resIndic=0.0;

               double plus =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               double minus =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);

               if(plus-minus>marge)
                 {
                  sens="UP";
                 }
               if(minus-plus>marge)
                 {
                  sens="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+StrToInteger(resParam[2]) && !croisement)
                 {
                  double plus_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,i);
                  double minus_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,i);

                  if(plus_prec-minus_prec>0)
                    {
                     sens_prec="UP";
                     if(sens=="NEUTRAL")
                       {
                        sens="UP";
                       }
                    }
                  if(minus_prec-plus_prec>0)
                    {
                     sens_prec="DOWN";
                     if(sens=="NEUTRAL")
                       {
                        sens="DOWN";
                       }
                    }

                  if(sens=="UP" && sens_prec=="DOWN")
                    {
                     resIndic=1.0;
                     croisement=true;
                    }
                  else
                    {
                     if(sens=="DOWN" && sens_prec=="UP")
                       {
                        resIndic=-1.0;
                        croisement=true;
                       }
                    }
                  i++;
                 }
              }
            return resIndic;
           }

         // Vortex_Direction : returns 1 if Plus and Minus+marge is in bulls way else -1
         //param : Param Vortex, marge, shift
         //ex : Vortex_Direction:14,0.01,1
         if(methode=="Vortex_Direction")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               double marge=StrToDouble(resParam[1]);
               string monIndic="Vortex_Indicator";
               resIndic=0.0;

               double plus =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);
               double minus =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),1,shift);

               if(plus-minus>marge)
                 {
                  resIndic=1.0;
                 }
               if(minus-plus>marge)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }


         // DEMA_Direction : returns the direction of DEMA : -1/ 1
         //param : period, shift
         //ex : DEMA_Direction:50,1
         if(methode=="DEMA_Direction")
           {
            if(ArraySize(resParam)==2)
              {
               int shift=StrToInteger(resParam[1]);
               string monIndic="DEMA";
               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // DEMA_Go : returns 1 if price crossed the DEMA line in last N bars in bull way
         // returns -1 if price crossed the DEMA line in last N bars in bear way
         //param : DEMA,N bars, shift
         //ex : DEMA_Go:50,7,1
         if(methode=="DEMA_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[2]);
               int nbbars=StrToInteger(resParam[1]);
               string monIndic="DEMA";
               string direction="",dir_prec="";
               bool cross=false;

               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),0,i);

                  if(val_prec>iClose(NULL,timeframe,i))
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // KAMA_Direction : returns the direction of KAMA : -1/ 1
         //param : kama_period,fast_ma_period,slow_ma_period, shift
         //ex : KAMA_Direction:10,2.0,30.0,1
         if(methode=="KAMA_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               string monIndic="KAMA";
               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // KAMA_Go : returns 1 if price crossed the KAMA line in last N bars in bull way
         // returns -1 if price crossed the KAMA line in last N bars in bear way
         //param : kama_period,fast_ma_period,slow_ma_period,N bars, shift
         //ex : KAMA_Go:10,2.0,30.0,7,1
         if(methode=="KAMA_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int nbbars=StrToInteger(resParam[3]);
               string monIndic="KAMA";
               string direction="",dir_prec="";
               bool cross=false;

               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,shift);

               if(iClose(symbol,timeframe,shift)-val>0)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0,i);

                  if(val_prec>iClose(NULL,timeframe,i))
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // HLCTrend_Direction : returns the direction of HLCTrend : -1/ 1
         //param : close_period,low_period,high_period, shift
         //ex : HLCTrend_Direction:3,7,20,1
         if(methode=="HLCTrend_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               string monIndic="HLCTrend";
               double val_f=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),0,shift);
               double val_s=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),1,shift);

               if(val_f>val_s)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // HLCTrend_Go : returns 1 if price crossed the KAMA line in last N bars in bull way
         // returns -1 if price crossed the KAMA line in last N bars in bear way
         //param : close_period,low_period,high_period,N bars, shift
         //ex : HLCTrend_Go:3,7,20,7,1
         if(methode=="HLCTrend_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int nbbars=StrToInteger(resParam[3]);
               string monIndic="HLCTrend";
               string direction="",dir_prec="";
               bool cross=false;

               double val_f=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),0,shift);
               double val_s=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),1,shift);

               if(val_f>val_s)
                 {
                  direction="UP";
                 }
               else
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec_f =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),0,i);
                  double val_prec_s =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),1,i);

                  if(val_prec_f>val_prec_s)
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     dir_prec="DOWN";
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // QQE_Direction : returns the direction of QQE : -1/ 1
         //param : RSI_Period, Smoothing_Period,cross line, shift
         //ex : QQE_Direction:14,5,50,1
         if(methode=="QQE_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               int ATR_Period=14;
               int line=StrToInteger(resParam[2]);
               double fast_ATR=2.618,slow_ATR=4.236;
               string monIndic="QualitativeQuantitativeEstimation";
               resIndic=0.0;

               double val_QQE=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,0,shift);
               double val_TS=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,1,shift);

               if(val_QQE>val_TS && val_QQE>line)
                 {
                  resIndic=1.0;
                 }
               if(val_QQE<val_TS && val_QQE<line)
                 {
                  resIndic=-1.0;
                 }
              }
            return resIndic;
           }

         // QQE_Go : returns 1 if price crossed the line in last N bars in bull way
         // returns -1 if price crossed the  line in last N bars in bear way
         //param : RSI_Period, Smoothing_Period,cross line,N bars, shift
         //ex : QQE_Go:14,5,50,7,1
         if(methode=="QQE_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int nbbars=StrToInteger(resParam[3]);
               int line=StrToInteger(resParam[2]);
               int ATR_Period=14;
               double fast_ATR=2.618,slow_ATR=4.236;
               string monIndic="QualitativeQuantitativeEstimation";
               string direction="NEUTRAL",dir_prec="NEUTRAL";
               bool cross=false;

               double val_QQE=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,0,shift);
               double val_TS=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,1,shift);

               if(val_QQE>val_TS && val_QQE>line)
                 {
                  direction="UP";
                 }
               if(val_QQE<val_TS && val_QQE<line)
                 {
                  direction="DOWN";
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec_QQE =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,0,i);
                  double val_prec_TS =iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),StrToInteger(resParam[1]),ATR_Period,fast_ATR,slow_ATR,1,i);

                  if(val_prec_QQE>val_prec_TS && val_prec_QQE>line)
                    {
                     dir_prec="UP";
                    }
                  if(val_prec_QQE<val_prec_TS && val_prec_QQE<line)
                    {
                     dir_prec="DOWN";
                    }

                  if(direction=="UP" && dir_prec!="UP")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec!="DOWN")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // Didi_Direction : returns the direction of Didi's slow line : -1/ 1
         //param : Short,Medium,Long, shift
         //ex : Didi_Direction:3,8,20,1
         if(methode=="Didi_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               int applied=PRICE_CLOSE, mode=MODE_SMA;
               string monIndic="Didi_Index";
               resIndic=0.0;

               double val=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),applied,mode,StrToInteger(resParam[1]),applied,mode,StrToInteger(resParam[2]),applied,mode,2,shift);

               if(val>1)
                 {
                  resIndic=-1.0;
                 }
               else
                 {
                  resIndic=1.0;
                 }
              }
            return resIndic;
           }

         // Didi_Go : returns 1 if slow line crossed the medium line in last N bars in bull way
         // returns -1 if price crossed the  line in last N bars in bear way
         //param : Short,Medium,Long ,N bars, shift
         //ex : Didi_Go:3,8,20,7,1
         if(methode=="Didi_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int nbbars=StrToInteger(resParam[3]);
               int applied=PRICE_CLOSE, mode=MODE_SMA;
               string monIndic="Didi_Index";
               string direction="NEUTRAL",dir_prec="NEUTRAL";
               bool cross=false;
               logMe(handle,9,"Didi_Go : "+nbbars,1);
               double val=0;
               val=iCustom(symbol,timeframe,"Didi_Index",3,0,0,8,0,0,20,0,0);
               if(val>1)
                 {
                  direction="DOWN";
                 }
               else
                 {
                  direction="UP";
                 }
               logMe(handle,9,"Didi_Go val : "+val+ " error : "+GetLastError(),1);

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec=iCustom(symbol,timeframe,monIndic,StrToInteger(resParam[0]),applied,mode,StrToInteger(resParam[1]),applied,mode,StrToInteger(resParam[2]),applied,mode,2,i);

                  if(val_prec>1)
                    {
                     dir_prec="DOWN";
                    }
                  else
                    {
                     dir_prec="UP";
                    }

                  if(direction=="UP" && dir_prec!="UP")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec!="DOWN")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // BBTrend_Flat_Direction : returns the direction of BBTrend_Flat : -1/ 1 / 0 if flat
         //param : BBPeriod,BBDeviation,FlatFactor, shift
         //ex : BBTrend_Flat_Direction:20,2.0,1.0,1
         if(methode=="BBTrend_Flat_Direction")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               resIndic=0.0;

               double val_u=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0, shift, handle);
               double val_d=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),1, shift, handle);

               if(val_u==1)
                 {
                  resIndic=1.0;
                 }
               else
                 {
                  if(val_d==1)
                    {
                     resIndic=-1.0;
                    }
                 }
              }
            return resIndic;
           }

         // BBTrend_Flat_Go : returns 1 if BB Trend went green in last N bars
         // returns -1 if BB Trend went red in last N bars
         //param : BBPeriod,BBDeviation,FlatFactor,N bars, shift
         //ex : BBTrend_Flat_Go:3,7,20,7,1
         if(methode=="BBTrend_Flat_Go")
           {
            if(ArraySize(resParam)==5)
              {
               int shift=StrToInteger(resParam[4]);
               int nbbars=StrToInteger(resParam[3]);

               string direction="",dir_prec="";
               bool cross=false;

               double val_u=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0, shift, handle);
               double val_d=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),1, shift, handle);

               if(val_u==1)
                 {
                  direction="UP";
                 }
               else
                 {
                  if(val_d==1)
                    {
                     direction="DOWN";
                    }
                 }

               int i=shift+1;
               while(i<=shift+nbbars && !cross)
                 {
                  double val_prec_u=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),0, i, handle);
                  double val_prec_d=getDefaultBBTrend_Flat(symbol, timeframe,StrToInteger(resParam[0]),StrToDouble(resParam[1]),StrToDouble(resParam[2]),1, i, handle);

                  if(val_prec_u==1)
                    {
                     dir_prec="UP";
                    }
                  else
                    {
                     if(val_prec_d==1)
                       {
                        dir_prec="DOWN";
                       }
                    }
                  if(direction=="UP" && dir_prec=="DOWN")
                    {
                     resIndic=1.0;
                     cross=true;
                    }
                  else
                    {
                     if(direction=="DOWN" && dir_prec=="UP")
                       {
                        resIndic=-1.0;
                        cross=true;
                       }
                    }
                  i++;
                 }
               if(!cross)
                 {
                  resIndic=0.0;
                 }
              }
            return resIndic;
           }

         // MACD_Go : returns 1 if MACD line crossed MACD signal in last bar in bull way AND MACD line is below 0
         // returns -1 if MACD line crossed MACD signal in last bar in bear way AND MACD line is above 0
         //param : MACD param 1,MACD param 2,MACD param 3, shift
         //ex : MACD_Go:12,26,9,1
         if(methode=="MACD_Go")
           {
            if(ArraySize(resParam)==4)
              {
               int shift=StrToInteger(resParam[3]);
               string direction="";
               resIndic=0.0;

               double line=iMACD(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),PRICE_CLOSE,0,shift);
               double signal=iMACD(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),PRICE_CLOSE,1,shift);

               if(line-signal>0 && line<0)
                 {
                  direction="UP";
                 }
               else
                 {
                  if(line-signal<0 && line>0)
                    {
                     direction="DOWN";
                    }
                 }

               if(direction!="")
                 {
                  shift++;
                  double line_prec=iMACD(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),PRICE_CLOSE,0,shift);
                  double signal_prec=iMACD(symbol,timeframe,StrToInteger(resParam[0]),StrToInteger(resParam[1]),StrToInteger(resParam[2]),PRICE_CLOSE,1,shift);

                  if(!(line_prec-signal_prec>0) && line_prec<0 && direction=="UP")
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     if(!(line_prec-signal_prec<0) && line_prec>0 && direction=="DOWN")
                       {
                        resIndic=-1.0;
                       }
                    }
                 }
              }
            return resIndic;
           }

         // Reverse_Candle_Go : returns 1 the candle selected is a bullish reverse candle, big low wick
         // returns -1 the candle selected is a bearish reverse candle, big high wick
         //param : shift, min percent TR, min percent wick size
         //ex : Reverse_Candle_Go:1,0.8,0.5
         if(methode=="Reverse_Candle_Go")
           {
            if(ArraySize(resParam)==3)
              {
               int shift=StrToInteger(resParam[0]);
               double candleTRMinRatio=StrToDouble(resParam[1]);
               double candleWickMinRatio=StrToDouble(resParam[2]);

               double high=iHigh(symbol,timeframe,shift);
               double low=iLow(symbol,timeframe,shift);
               double close=iClose(symbol,timeframe,shift);
               double open=iOpen(symbol,timeframe,shift);

               resIndic=0.0;

               double ATR=iATR(symbol,timeframe,14,shift);
               double TR=high-low;

               if(TR>=candleTRMinRatio*ATR)
                 {
                  if(open-low>=candleWickMinRatio*TR && close-low>=candleWickMinRatio*TR)
                    {
                     resIndic=1.0;
                    }
                  else
                    {
                     if(high-open>=candleWickMinRatio*TR && high-close>=candleWickMinRatio*TR)
                       {
                        resIndic=-1.0;
                       }
                    }
                 }

              }
            return resIndic;
           }

        }

     }

   return resIndic;
  }

//+------------------------------------------------------------------+

//simplify the call for ALMA with default values
//for line index, use 0 for value of the line and 3 for direction (1/-1)
double getDefaultALMA(string symbol, int timeframe,int paramWindowSize, int lineIndex, int shift,int handle)
  {
   double res=iCustom(symbol,timeframe,"ALMA_v2.1_ATR_Bands",0,paramWindowSize,6.0,0.85,0,0,0,false,1.0,1,0,0,0,false,lineIndex,shift);
   return res;
  }

//simplify the call for BBTrend_Flat with default values
//for line index, use 0 for value of the green and 1 for the red
double getDefaultBBTrend_Flat(string symbol, int timeframe,int BBPeriod,double BBDeviation,double FlatFactor, int lineIndex, int shift,int handle)
  {
   double res=iCustom(symbol,timeframe,"BB Trend Flat","",BBPeriod,BBDeviation,FlatFactor,false,false,9,clrRed,clrRed,clrRed,"",false,false,false,false,lineIndex,shift);
   if(res==EMPTY_VALUE)
     {
      res=0.0;
     }
   return res;
  }

// getOpenPriceGivenTime : returns oen price for a time in param
//input : givenTime : time formatted HHMI,isToday is we check the candle for today or yesterday
//eg : getOpenPriceGivenTime(EURUSD, 1830, false)
double getOpenPriceGivenTime(string symbol, string givenTime, bool isToday,int handle)
  {
#define HR24 86400 // 24*3600
   datetime now = TimeCurrent();
   datetime myTime;
   int      TOD = now % HR24;   // Time of day (date+time)
   datetime BOD = now - TOD;    // Beginning of day+0000z
   int givenTimeInt=StrToInteger(givenTime);

   int hTime=MathFloor(givenTimeInt/100.0);
   int minTime=MathMod(givenTimeInt,100.0);
   int secTime=hTime*3600+minTime*60;

   if(isToday)
     {
      myTime=BOD+secTime;
     }
   else
     {
      int nbSecAfterTime=HR24-secTime;
      myTime=BOD-nbSecAfterTime;
     }
   int myCandleM30=iBarShift(symbol, PERIOD_M30, myTime);
   double openTime=iOpen(symbol, PERIOD_M30, myCandleM30);

   return openTime;

  }


//+------------------------------------------------------------------+
