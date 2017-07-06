#include <NewSoftSerial.h>

NewSoftSerial mySerial(6, 7);

byte incomingBuffer[256];
int bufferSize = 0;

void pack(char *input, char *output)
{
  int len = strlen(input);
  
  unsigned char c, w;
  int n, shift, x;
  shift = 0; output[0] = 0;

  for (int n=0; n<len; ++n)
  {
        c = input[n] & 0x7f;
        c >>= shift;
        w = input[n+1] & 0x7f;
        w <<= (7-shift);
        shift +=1;
        c = c | w;
        if (shift == 7)
        {
          shift = 0x00;
          n++;
        }
        
        x = strlen(output);
        output[x] = c;
        output[x+1] = 0;
    }
}

void setup()  
{
  Serial.begin(115200);

  // set the data rate for the NewSoftSerial port
  mySerial.begin(115200);
  
  initialize();
//  getVersion();
  getPhoneId();
//  getNetworkInfo();
//  getSms();
/*
  char message[] = "hello";
  
  char packed[strlen(message)];
  
  pack(message, packed);   
  
  for(int i = 0; i < strlen(packed); i++)
  {
      Serial.print(packed[i], HEX);
      Serial.print(" ");
  }
  */
}

void writeFrame(byte* frame, int length)
{
  // init header
  
  // use fbus cable
  mySerial.print(0x1E, BYTE); 
  
  // to cell
  mySerial.print(0x00, BYTE); 
  
  // from pc
  mySerial.print(0x0C, BYTE); 
  
  for (int i = 0; i < length; i++) 
  {
    Serial.print(frame[i], HEX);
    Serial.print(" ");
    mySerial.print(frame[i], BYTE);
  }
  
  // calculate check sums
  byte evenChecksum = 0x1E ^ 0x0C;
  byte oddChecksum = 0;
  
  for(int i = 0; i < 9; i+=2)
  {
    evenChecksum ^= frame[i+1];
  }

  for(int i = 0; i < 11; i+=2)
  {
    oddChecksum ^= frame[i];
  }
  
  mySerial.print(evenChecksum, BYTE);
  mySerial.print(oddChecksum, BYTE);

/*  
  Serial.println("");
  Serial.print(evenChecksum, HEX);
  Serial.println("");
  Serial.print(oddChecksum, HEX);
  */
}

void initialize()
{
  for(int i = 0; i < 128; i++)
  { 
    mySerial.print(0x55, BYTE); 
    delay(5);
  }
  
  delay(5);
}

void getSms()
{
  byte data[] = {0x02,0x00,0x08,0x00,0x01,0x00,0x07,0x02,0x02,0x01,0x64};
  writeFrame(data, 11);
}

void getVersion()
{
  byte data[] = {0xD1, 0x00, 0x07, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x60, 0x00};
  writeFrame(data, 11);
}  

void getPhoneId()
{
  
  byte data[] = {0x04, 0x00, 0x07, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00};
  writeFrame(data, 11);
}  

void getPhoneInfo()
{
  
  byte data[] = {0x64, 0x00, 0x07, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00};
  writeFrame(data, 11);
}  

void getNetworkInfo()
{
  
  byte data[] = {0x0A, 0x00, 0x07, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00};
  writeFrame(data, 11);
}  

void ack()
{
  byte data[] = {0x7F, 0x00, 0x02, 0xD2, 0x01};
  writeFrame(data, 5);
}

void parseResponse()
{
    for(int i = 0; i < bufferSize; i++)
    {
      Serial.print(incomingBuffer[i], HEX);
      
      incomingBuffer[i] = 0;
    }
}

void loop()                     
{
  if (mySerial.available()) {
      incomingBuffer[bufferSize] = mySerial.read();
      bufferSize++;
  }
  else
  {
    if(bufferSize > 0)
    {
      parseResponse();
      
      bufferSize = 0;
//      ack();
    } 
  }
}
