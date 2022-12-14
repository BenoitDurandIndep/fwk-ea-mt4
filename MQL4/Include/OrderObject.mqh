//+------------------------------------------------------------------+
//|                                                  OrderObject.mqh |
//|                    Bases on KlondikeFX upgraded by Benoit Durand |
//|                                        http://www.klondikefx.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, KlondikeFX and Benoit Durand"
#property strict

#include <MoneyManagement.mqh>

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
/**
* filter defines
*/
#define FILTER_MARKET         1
#define FILTER_PENDING        2
#define FILTER_LONG           3
#define FILTER_SHORT          4
#define MYFILTER              5

/**
* sorting defines
*/
#define ORDER_TICKET          0
#define ORDER_TYPE            1
#define ORDER_MAGIC_NUMBER    2
#define ORDER_LOTS            3
#define ORDER_OPEN_PRICE      4
#define ORDER_CLOSE_PRICE     5
#define ORDER_OPEN_TIME       6
#define ORDER_CLOSE_TIME      7
#define ORDER_NET_PROFIT      8  // Profit + Swap + Commission
#define ORDER_STOP_LOSS       9
#define ORDER_TAKE_PROFIT     10

#define ASCENDING             -1
#define DESCENDING            1
#define NEWEST                DESCENDING
#define OLDEST                ASCENDING

//+------------------------------------------------------------------+
//| Order class                                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Order
  {
public:

   int               ticket;
   int               type;
   int               sens; // if 1 long, if -1 short, if 0 error !
   int               magic;
   double            lots;
   double            openLots;
   double            openPrice;
   double            closePrice;
   datetime          openTime;
   datetime          closeTime;
   double            profit;
   double            swap;
   double            commission;
   double            stopLoss;
   double            openStopLoss;
   double            takeProfit;
   datetime          expiration;
   string            comment;
   string            symbol;
   int               pyramidPosition;

   //calculated ratios
   double            openProfitDoable;
   double            openLossDoable;
   double            lossDoable;
   double            openRisk;
   double            risk;
   double            openRewardRatio;
   double            currentRewardRatio;

   void              Order() // default constructor
     {
      pyramidPosition=0;
     }

   void              Order(const int pTicket) // constructor with a ticket
     {
      ticket=pTicket;

      double val=MarketInfo(Symbol(),MODE_TICKVALUE);

      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         type=OrderType();
         sens=getSens(type);
         magic=OrderMagicNumber();
         lots=OrderLots();
         if(openLots==NULL)
           {
            openLots=OrderLots();
           }
         openPrice=OrderOpenPrice();
         openTime=OrderOpenTime();
         profit=OrderProfit();
         swap=OrderSwap();
         commission=OrderCommission();
         stopLoss=OrderStopLoss();
         if(openStopLoss==NULL)
           {
            openStopLoss=OrderStopLoss();
           }
         takeProfit=OrderTakeProfit();
         expiration=OrderExpiration();
         comment=OrderComment();
         symbol=OrderSymbol();
         pyramidPosition=0;

         openProfitDoable=getProfitPossible(lots,takeProfit,openPrice); // calcul du profit possible
         openLossDoable=getLossPossible(lots,stopLoss,openPrice,sens);
         lossDoable=getLossPossible(lots,stopLoss,openPrice,sens);

         openRisk=NormalizeDouble(-openLossDoable/AccountEquity()*100,2);

         if(openLossDoable<0)
           {
            openRewardRatio=NormalizeDouble(-openProfitDoable/openLossDoable,1);
           }
         else
           {
            openRewardRatio=0.0;
           }

         if(lossDoable<0)
           {
            risk=NormalizeDouble(-lossDoable/AccountEquity()*100,2);
           }
         else
           {
            risk=0.0;//exit with win
           }
         if(openLossDoable>=0.0)
           {
            currentRewardRatio=NormalizeDouble(-profit/-1,1);
           }
         else
           {
            currentRewardRatio=NormalizeDouble(-profit/openLossDoable,1);
           }
        }
     }

   int               getSens(int pType)
     {
      if(pType==OP_BUY || pType==OP_BUYLIMIT || pType==OP_BUYSTOP)
        {
         return 1;
        }
      else
         if(pType==OP_SELL || pType==OP_SELLLIMIT || pType==OP_SELLSTOP)
           {
            return -1;
           }
         else
           {
            return 0;
           }
     }

   double            updateProfit()
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         profit=OrderProfit();
         return profit;
        }
      return -1;
     }

   double            updateSwap()
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         swap=OrderSwap();
         return swap;
        }
      return -1;
     }

   double            updateCommission()
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         commission=OrderCommission();
         return commission;
        }
      return -1;
     }

   double            updateStopLoss()
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         stopLoss=OrderStopLoss();
         return stopLoss;
        }
      return -1;
     }

   double            updateTakeProfit()
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         takeProfit=OrderTakeProfit();
         return takeProfit;
        }
      return -1;
     }

   double            updateLossDoable()
     {
      lossDoable=getLossPossible(lots,stopLoss,openPrice,sens);
      return lossDoable;
     }


   double            updateRisk()
     {
      if(lossDoable<0)
        {
         risk=NormalizeDouble(-lossDoable/AccountEquity()*100,2);
        }
      else
        {
         risk=0.0;
        }
      return risk;

     }

   double            updateRewardRatio()
     {
      currentRewardRatio=NormalizeDouble(-profit/openLossDoable,1);
      return currentRewardRatio;
     }

   //updates informations of an order
   void              updateOrder() 
     {
      updateProfit();
      updateSwap();
      updateCommission();
      updateStopLoss();
      updateTakeProfit();
      updateLossDoable();
      updateRisk();
      updateRewardRatio();
     }

  };

//+------------------------------------------------------------------+
//| OrderSelection class                                             |
//+------------------------------------------------------------------+
/**
* Container for a selection of orders
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class OrderSelection
  {
private:

   Order*            orders[];  // array of order objects
   int               index;        // index of current order
   int               size;         // number of all orders in container

public:

   void              OrderSelection() // constructor for container
     {
      index = -1;
      size = 0;
     }

   void             ~OrderSelection()  // destructor frees the memory
     {
      for(int i = 0; i < ArraySize(orders); i ++)
         delete(orders[i]);
     }

   int               Count() const // returns count of all orders in container
     {
      return(size);
     }

   bool              End()  // returns true if index is at the end of container
     {
      return(index >= (size - 1));
     }

   void              Rewind() // resets the container index
     {
      index = -1;
     }

   Order*            Get(int _index)  // returns order object with index
     {
      return(orders[_index]);
     }

   Order*            Current()  // returns the current order object of container (used by next and prev)
     {
      return(orders[index]);
     }

   Order*            Prev() // returns the previous order object of container
     {
      index --;

      if(index < 0)
         return(NULL);

      return(Current());
     }

   Order*            Next()  // returns the next order object of container
     {
      index ++;

      if(index >= size)
        {
         Rewind();
         return(NULL);
        }

      return(Current());
     }

   void              Insert(Order* _order) // adds an order to container
     {
      size ++;
      ArrayResize(orders, size);
      orders[(size - 1)] = _order;
     }

   void              Delete(int _index) // delete an order to container
     {
      delete(orders[_index]);
     }

   void              Sort(int _what = ORDER_TICKET, int _direction = ASCENDING) // insertion sort
     {
      int i,j;
      for(i = 1; i < size; i++)
        {
         j = i;
         while(j > 0 && Compare(orders[j], orders[j - 1], _what, _direction))
           {
            Order* temp = orders[j];
            orders[j]= orders[j - 1];
            orders[j - 1] = temp;
            j--;
           }
        }
     }

   string            PrintOrderSelection()
     {
      string maStr="| ";
      for(int i = 0; i < size; i++)
        {
         Order* temp = orders[i];
         maStr+="Ticket "+temp.ticket+" num "+IntegerToString(i)+" : Open at "+DoubleToStr(temp.openPrice,5)+" Size "+DoubleToStr(temp.lots,2);
         maStr+=" SL "+DoubleToStr(temp.stopLoss,5)+" Open SL "+DoubleToStr(temp.openStopLoss,5)+" Current risk "+DoubleToStr(temp.risk,2)+" Current reward ratio "+DoubleToStr(temp.currentRewardRatio,1)+":1| |";
        }
      return maStr;
     }

   double            getRiskToral()
     {
      double monRisk=0.0;
      for(int i = 0; i < size; i++)
        {
         Order* temp = orders[i];
         monRisk+=temp.risk;
        }

      return monRisk;
     }

   double            TotalPosition()  const
     {
      double maPosition=0.0;
      for(int i = 0; i < size; i++)
        {
         Order* temp = orders[i];
         maPosition+=temp.lots;
        }

      return maPosition;
     }

   //getIndexFromTicket : search an order with the ticket and returns the index of this order
   //if the order doesn't exist returns-1
   int               getIndexFromTicket(int pTicket)
     {
      int i=0, resIndex=-1;

      while(i < size && resIndex<0)
        {
         Order* temp = orders[i];
         if(temp.ticket==pTicket)
           {
            resIndex=i;
           }
         i++;
        }
      return resIndex;
     }

private:

   // Compare : comparision function for sort
   bool              Compare(Order* _o1, Order* _o2, int _what, int _direction)
     {
      switch(_what)
        {
         case ORDER_TICKET:
            return (_o1.ticket - _o2.ticket) * _direction >= 0;
         case ORDER_MAGIC_NUMBER:
            return (_o1.magic - _o2.magic) * _direction >= 0;
         case ORDER_TYPE:
            return (_o1.type - _o2.type) * _direction >= 0;
         case ORDER_CLOSE_PRICE:
            return (_o1.closePrice - _o2.closePrice) * _direction >= 0;
         case ORDER_CLOSE_TIME:
            return (_o1.closeTime - _o2.closeTime) * _direction >= 0;
         case ORDER_OPEN_PRICE:
            return (_o1.openPrice - _o2.openPrice) * _direction >= 0;
         case ORDER_OPEN_TIME:
            return (_o1.openTime - _o2.openTime) * _direction >= 0;
         case ORDER_LOTS:
            return (_o1.lots - _o2.lots) * _direction >= 0;
         case ORDER_NET_PROFIT:
            return ((_o1.profit + _o1.swap + _o1.commission) -
                    (_o2.profit + _o2.swap + _o2.commission)) * _direction >= 0;
         case ORDER_STOP_LOSS:
            return (_o1.stopLoss - _o2.stopLoss) * _direction >= 0;
         case ORDER_TAKE_PROFIT:
            return (_o1.takeProfit - _o2.takeProfit) * _direction >= 0;
         default:
            return true;
        }
     }

  };

//+------------------------------------------------------------------+
//| OrderWorker class                                                |
//+------------------------------------------------------------------+
/**
* class for working with Metatrader Orders
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class OrderWorker
  {
public:

   void             ~OrderWorker()
     {}

   static OrderSelection* GetOpen(int _magic = NULL, string _symbol = NULL, int _type = NULL, int _filter = NULL)
     {
      OrderSelection* orders = new OrderSelection();  // new container for orders

      for(int i = OrdersTotal() - 1; i >= 0; i --)
        {
         bool selected = OrderSelect(i, SELECT_BY_POS);

         if(selected)
           {
            Order* order = new Order();   // create new order object
            Fill(order);     // fill order object

            if(true
               && (_magic == NULL || _magic == order.magic)
               && (_type == NULL || _type == order.type)
               && (_symbol == NULL || _symbol == order.symbol)
               && (_filter == NULL || Helper::Filter(order, _filter))   // do advanced selections
              )

               orders.Insert(order); // add object to container

            else
               delete(order); // remove from memory
           }
        }
      return orders;
     }

   //UpdateOrderBook : updates the order book with a magic
   // create a new order book
   //if a ticket exists in the old book, updates it with the data of the old one
   //return the new book
   static OrderSelection* UpdateOrderBook(OrderSelection* oldOrderBook,int _magic = NULL, string _symbol = NULL, int _type = NULL, int _filter = NULL)
     {
      //creates the new book
      OrderSelection* newOrders = new OrderSelection();  // new container for orders

      for(int i = 0 ; i < OrdersTotal() ; i ++)
        {
         bool selected = OrderSelect(i, SELECT_BY_POS);

         if(selected)
           {
            Order* order = new Order(OrderTicket());   // create new order object
            //Fill(order);     // fill order object

            if(true        // test si l'ordre correspond aux critères
               && (_magic == NULL || _magic == order.magic)
               && (_type == NULL || _type == order.type)
               && (_symbol == NULL || _symbol == order.symbol)
               && (_filter == NULL || Helper::Filter(order, _filter))   // do advanced selections
              )
              {
               //if the ticket exists in the old book, we get his data
               int j=0;
               bool found=false;
               while(j<oldOrderBook.Count() && !found)
                 {
                  Order* oldOrder=oldOrderBook.Get(j);
                  if(oldOrder.ticket==order.ticket)
                    {
                     order.openLossDoable=oldOrder.openLossDoable;
                     order.openLots=oldOrder.openLots;
                     order.openPrice=oldOrder.openPrice;
                     order.openProfitDoable=oldOrder.openProfitDoable;
                     order.openRewardRatio=oldOrder.openRewardRatio;
                     order.openRisk=oldOrder.openRisk;
                     order.openStopLoss=oldOrder.openStopLoss;
                     order.openTime=oldOrder.openTime;

                     found=true;
                    }
                  j++;
                 }

               newOrders.Insert(order); // add object to container
              }
            else
              {
               delete(order); // remove from memory
              }
           }
        }
      delete(oldOrderBook);
      return newOrders;

     }

   // TO FINISH ?
   static OrderSelection* GetOpenTicket(int _magic = NULL, string _symbol = NULL, int _type = NULL, int _filter = NULL)
     {
      OrderSelection* orders = new OrderSelection();  // new container for orders

      for(int i = 0 ; i <= OrdersTotal() - 1; i ++)
        {
         bool selected = OrderSelect(i, SELECT_BY_POS);

         if(selected)
           {
            Order* order = new Order(OrderTicket());   // create new order object
            //Fill(order);     // fill order object

            if(true
               && (_magic == NULL || _magic == order.magic)
               && (_type == NULL || _type == order.type)
               && (_symbol == NULL || _symbol == order.symbol)
               && (_filter == NULL || Helper::Filter(order, _filter))   // do advanced selections
              )
              {
               orders.Insert(order); // add object to container

              }
            else
              {
               delete(order); // remove from memory
              }
           }
        }
      return orders;
     }

   static OrderSelection* GetHistory(int _magic = NULL, string _symbol = NULL, int _type = NULL, int _filter = NULL)
     {
      OrderSelection *orders = new OrderSelection();  // new container for orders

      for(int i = OrdersHistoryTotal() - 1; i >= 0; i --)
        {
         bool selected = OrderSelect(i, SELECT_BY_POS, MODE_HISTORY);

         if(selected)
           {
            Order* order = new Order();   // create new order object
            Fill(order);     // fill order object

            if(true
               && (_magic == NULL || _magic == order.magic)
               && (_type == NULL || _type == order.type)
               && (_symbol == NULL || _symbol == order.symbol)
               && (_filter == NULL || Helper::Filter(order, _filter))   // do advanced selections
              )

               orders.Insert(order); // add object to container

            else
               delete(order); // remove from memory

           }
        }
      return orders;
     }

private:

   static void       Fill(Order &order)
     {
      order.ticket = OrderTicket();
      order.type = OrderType();
      order.magic = OrderMagicNumber();
      order.lots = OrderLots();
      order.openPrice = OrderOpenPrice();
      order.closePrice = OrderClosePrice();
      order.openTime = OrderOpenTime();
      order.closeTime = OrderCloseTime();
      order.profit = OrderProfit();
      order.swap = OrderSwap();
      order.commission = OrderCommission();
      order.stopLoss = OrderStopLoss();
      order.takeProfit = OrderTakeProfit();
      order.expiration = OrderExpiration();
      order.comment = OrderComment();
      order.symbol = OrderSymbol();
      order.openStopLoss=OrderStopLoss();
     }
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Helper
  {
public:

   static datetime   MyDate(datetime _date = NULL)
     {
      static datetime date_saved;
      if(_date != NULL)
         date_saved = _date;
      return(date_saved);
     }

   static bool       Filter(Order* _order, int _filter)  // additional filter function for order selection
     {
      int type = _order.type;

      switch(_filter)
        {
         case FILTER_LONG:
            return(Direction(type) > 0);
         case FILTER_SHORT:
            return(Direction(type) < 0);
         case FILTER_MARKET:
            return(type >= OP_BUY && type <= OP_SELL);
         case FILTER_PENDING:
            return(type > OP_SELL && type <= OP_SELLSTOP);
         case MYFILTER:
            return(_order.openTime < MyDate());
        }
      return true;
     }

   static int        Direction(int _type) // returns 1 for long and -1 for short
     {
      if(_type < OP_BUY || _type > OP_SELLSTOP) // no valid order type
         return(0);
      if(_type % 2 > 0)
         return(-1);
      return(1);
     }
  };

//+------------------------------------------------------------------+
