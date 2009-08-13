use Test::Base;

plan tests => 35;

use AnyEvent::Gearman::Constants;

is 1,  CAN_DO;                #  REQ    Worker
is 2,  CANT_DO;               #  REQ    Worker
is 3,  RESET_ABILITIES;       #  REQ    Worker
is 4,  PRE_SLEEP;             #  REQ    Worker
                              #  -      -
is 6,  NOOP;                  #  RES    Worker
is 7,  SUBMIT_JOB;            #  REQ    Client
is 8,  JOB_CREATED;           #  RES    Client
is 9,  GRAB_JOB;              #  REQ    Worker
is 10, NO_JOB;                #  RES    Worker
is 11, JOB_ASSIGN;            #  RES    Worker
is 12, WORK_STATUS;           #  REQ    Worker
                              #  RES    Client
is 13, WORK_COMPLETE;         #  REQ    Worker
                              #  RES    Client
is 14, WORK_FAIL;             #  REQ    Worker
                              #  RES    Client
is 15, GET_STATUS;            #  REQ    Client
is 16, ECHO_REQ;              #  REQ    Client/Worker
is 17, ECHO_RES;              #  RES    Client/Worker
is 18, SUBMIT_JOB_BG;         #  REQ    Client
is 19, ERROR;                 #  RES    Client/Worker
is 20, STATUS_RES;            #  RES    Client
is 21, SUBMIT_JOB_HIGH;       #  REQ    Client
is 22, SET_CLIENT_ID;         #  REQ    Worker
is 23, CAN_DO_TIMEOUT;        #  REQ    Worker
is 24, ALL_YOURS;             #  REQ    Worker
is 25, WORK_EXCEPTION;        #  REQ    Worker
                              #  RES    Client
is 26, OPTION_REQ;            #  REQ    Client/Worker
is 27, OPTION_RES;            #  RES    Client/Worker
is 28, WORK_DATA;             #  REQ    Worker
                              #  RES    Client
is 29, WORK_WARNING;          #  REQ    Worker
                              #  RES    Client
is 30, GRAB_JOB_UNIQ;         #  REQ    Worker
is 31, JOB_ASSIGN_UNIQ;       #  RES    Worker
is 32, SUBMIT_JOB_HIGH_BG;    #  REQ    Client
is 33, SUBMIT_JOB_LOW;        #  REQ    Client
is 34, SUBMIT_JOB_LOW_BG;     #  REQ    Client
is 35, SUBMIT_JOB_SCHED;      #  REQ    Client
is 36, SUBMIT_JOB_EPOCH;      #  REQ    Client

