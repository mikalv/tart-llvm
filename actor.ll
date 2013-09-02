;
; actor.ll -- Tiny Actor Run-Time
;
; "MIT License"
; 
; Copyright (c) 2013 Dale Schumacher, Tristan Slominski
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
; THE SOFTWARE.
;

;
; "fog cutter"
;
; Actor  [*|...]
;         |
;         V
;        BEH
; 
; Value  [*|*]
;         | +--> DATA
;         V
;        CODE
; 
; Serial [*|*|*]---+
;         | |      V
;         | +---> [*|*]
;         V        | +--> STATE
;    act_serial    V
;                 STRATEGY
; 
; Pair   [*|*|*]
;         | | +--> tail
;         | +--> head
;         V
;      beh_pair
; 

; using C memory allocator for now
declare noalias i8* @calloc(i64, i64) #0
declare void @free(i8*) #0

; TRACE utilities
declare i32 @fprintf(%struct._IO_FILE*, i8*, ...) nounwind
%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }
@stderr = external global %struct._IO_FILE*

; HALT utilities
@.str.halt = private unnamed_addr constant [6 x i8] c"HALT!\00", align 1
declare void @llvm.trap() noreturn nounwind
@.str.halted = private unnamed_addr constant [21 x i8] c"%s **** HALTED ****\0A\00", align 1
define cc 10 void @halt(i8* %msg) #0 {
    %stderr = load %struct._IO_FILE** @stderr, align 8
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([21 x i8]* @.str.halted, i32 0, i32 0), i8* %msg)
    call void @llvm.trap()
    unreachable

    ret void
}

%any        = type i8* ; void pointer
%void       = type i8* ; void pointer

%behavior   = type void (%event*)
%actor      = type { %behavior* }
%pair       = type { %actor, %actor*, %actor* }
%value      = type { %actor, %any }
%serial     = type { %actor, %actor*, %actor* }
%event      = type { %actor, %config*, %actor*, %actor* }
%fail       = type void (%config*, %actor*)
%create     = type %actor* (%config*, i64, %behavior*)
%destroy    = type void (%config*, %actor*)
%send       = type void (%config*, %actor*, %actor*)
%config     = type { %actor, %fail*, %create*, %destroy*, %send*, %actor* }

@the_nil_pair_actor = global %pair { %actor { %behavior* @beh_pair }, %actor* getelementptr inbounds (%pair* @the_nil_pair_actor, i32 0, i32 0), %actor* getelementptr inbounds (%pair* @the_nil_pair_actor, i32 0, i32 0) }
@the_true_actor = global %actor { %behavior* @comb_true }
@the_false_actor = global %actor { %behavior* @comb_false }
define cc 10 void @beh_ignore(%event* %e) {
    ret void
}
@the_ignore_actor = global %actor { %behavior* @beh_ignore }
define cc 10 void @beh_halt(%event* %e) {
    tail call cc 10 void @halt(i8* getelementptr inbounds ([6 x i8]* @.str.halt, i32 0, i32 0))
    unreachable

    ret void
}
@the_halt_actor = global %value { %actor { %behavior* @beh_halt }, %any bitcast(%actor* getelementptr inbounds (%value* @the_halt_actor, i32 0, i32 0) to %any) }

define cc 10 void @beh_pair(%event* %e) {
    ; TODO: implement
    ret void
}
define cc 10 %actor* @pair_new(%config* %cfg, %actor* %h, %actor* %t) inlinehint {
    ; Pair p = (Pair)config_create(cfg, sizeof(PAIR), beh_pair)
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %p.1 = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 3, %behavior* @beh_pair)
    %p.2 = bitcast %actor* %p.1 to %pair*
    ; p->h = NIL;
    %p.h = getelementptr inbounds %pair* %p.2, i32 0, i32 1
    store %actor* %h, %actor** %p.h, align 8
    ; p->t = NIL;
    %p.t = getelementptr inbounds %pair* %p.2, i32 0, i32 2
    store %actor* %t, %actor** %p.t, align 8
    ; return (Actor)p;
    ret %actor* %p.1
}

define cc 10 void @beh_deque(%event* %e) {
    ; TODO: implement
    ret void
}
define cc 10 %actor* @deque_new(%config* %cfg) inlinehint {
    ; Pair p = (Pair)config_create(cfg, sizeof(PAIR), beh_deque)
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %p.1 = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 3, %behavior* @beh_deque)
    %p.2 = bitcast %actor* %p.1 to %pair*
    ; p->h = NIL;
    %p.h = getelementptr inbounds %pair* %p.2, i32 0, i32 1
    store %actor* bitcast (%pair* @the_nil_pair_actor to %actor*), %actor** %p.h, align 8
    ; p->t = NIL;
    %p.t = getelementptr inbounds %pair* %p.2, i32 0, i32 2
    store %actor* bitcast (%pair* @the_nil_pair_actor to %actor*), %actor** %p.t, align 8
    ; return (Actor)p;
    ret %actor* %p.1
}
@.str.deque_empty_p_deque_required = private unnamed_addr constant [30 x i8] c"deque_empty_p: deque required\00", align 1
define cc 10 %actor* @deque_empty_p(%config* %cfg, %actor* %queue) inlinehint {
    ; if (beh_deque != BEH(queue)) { halt("deque_empty_p: deque required"); }
    ; #define BEH(a)      (((Actor)(a))->beh)
    %cfg.beh.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 0
    %cfg.beh.fptr = bitcast %actor* %cfg.beh.fpp to %behavior*
    %beh_not_equal = icmp ne %behavior* @beh_deque, %cfg.beh.fptr
    br i1 %beh_not_equal, label %halt, label %proceed

proceed:
    ; return ((q->h == NIL) ? a_true : a_false);
    %q = bitcast %actor* %queue to %pair*
    %q.h.pp = getelementptr inbounds %pair* %q, i32 0, i32 1
    %q.h.ptr = load %actor** %q.h.pp, align 8
    %head_is_not_NIL = icmp ne %actor* %q.h.ptr, bitcast (%pair* @the_nil_pair_actor to %actor*)
    br i1 %head_is_not_NIL, label %deque_not_empty, label %deque_empty

deque_not_empty:
    ret %actor* @the_false_actor

deque_empty:
    ret %actor* @the_true_actor

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([30 x i8]* @.str.deque_empty_p_deque_required, i32 0, i32 0))
    unreachable
}
@.str.deque_give_deque_required = private unnamed_addr constant [27 x i8] c"deque_give: deque required\00", align 1
define cc 10 void @deque_give(%config* %cfg, %actor* %queue, %actor* %item) inlinehint {
    ; if (beh_deque != BEH(queue)) { halt("deque_give: deque required"); }
    ; #define BEH(a)      (((Actor)(a))->beh)
    %cfg.a = bitcast %config* %cfg to %actor*
    %cfg.a.beh.fpp = getelementptr inbounds %actor* %cfg.a, i32 0, i32 0
    %cfg.a.beh.fptr = load %behavior** %cfg.a.beh.fpp, align 8
    %beh_not_equal = icmp ne %behavior* @beh_deque, %cfg.a.beh.fptr
    br i1 %beh_not_equal, label %halt, label %proceed

proceed:
    ; Actor p = pair_new(cfg, item, NIL);
    %p.ptr = tail call cc 10 %actor* @pair_new(%config* %cfg, %actor* %item, %actor* bitcast (%pair* @the_nil_pair_actor to %actor*))
    ; if (q->h == NIL)
    %q = bitcast %actor* %queue to %pair*
    %q.h.pp = getelementptr inbounds %pair* %q, i32 0, i32 1
    %q.h.ptr = load %actor** %q.h.pp, align 8
    %q.t.pp = getelementptr inbounds %pair* %q, i32 0, i32 2
    %q.t.ptr = load %actor** %q.t.pp, align 8
    %q.t.3 = bitcast %actor* %q.t.ptr to %pair*
    %head_is_not_NIL = icmp ne %actor* %q.h.ptr, bitcast (%pair* @the_nil_pair_actor to %actor*)
    br i1 %head_is_not_NIL, label %deque_not_empty, label %deque_empty

deque_not_empty:
    ; Pair t = (Pair)(q->t);
    ; t->t = p;
    %t.pp = getelementptr inbounds %pair* %q.t.3, i32 0, i32 2
    store %actor* %p.ptr, %actor** %t.pp, align 8
    br label %finalize

deque_empty:
    ; q->h = p;
    store %actor* %p.ptr, %actor** %q.h.pp, align 8
    br label %finalize

finalize:
    ; q->t = p;
    store %actor* %p.ptr, %actor** %q.t.pp, align 8
    ret void    

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([27 x i8]* @.str.deque_give_deque_required, i32 0, i32 0))
    unreachable
}
@.str.deque_take_from_empty = private unnamed_addr constant [24 x i8] c"deque_take: from empty!\00", align 1
define cc 10 %actor* @deque_take(%config* %cfg, %actor* %queue) inlinehint {
    ; if (deque_empty_p(cfg, queue) != a_false) { halt("deque_take from empty!"); }
    ; #define a_false ((Actor)(&the_false_actor))
    %empty_check_result = tail call cc 10 %actor* @deque_empty_p(%config* %cfg, %actor* %queue)
    %is_empty = icmp ne %actor* %empty_check_result, @the_false_actor
    br i1 %is_empty, label %halt, label %deque_not_empty

deque_not_empty:
    ; Pair p = (Pair)(q->h);
    %q = bitcast %actor* %queue to %pair*
    %q.h.pp = getelementptr inbounds %pair* %q, i32 0, i32 1
    %q.h.ptr = load %actor** %q.h.pp, align 8
    %p = bitcast %actor* %q.h.ptr to %pair*
    ; Actor item = p->h;
    %p.h.pp = getelementptr inbounds %pair* %p, i32 0, i32 1
    %item = load %actor** %p.h.pp, align 8
    ; q->h = p->t;
    %p.t.pp = getelementptr inbounds %pair* %p, i32 0, i32 2
    %p.t.ptr = load %actor** %p.t.pp, align 8
    store %actor* %p.t.ptr, %actor** %q.h.pp
    ; config_destroy(cfg, (Actor)p);
    ; #define         config_destroy(cfg, victim)     (((cfg)->destroy)((cfg), (victim)))
    %cfg.destroy.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 3
    %cfg.destroy.fptr = load %destroy** %cfg.destroy.fpp, align 8
    tail call cc 10 void %cfg.destroy.fptr(%config* %cfg, %actor* %q.h.ptr)
    ; return item;
    ret %actor* %item

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([24 x i8]* @.str.deque_take_from_empty, i32 0, i32 0))
    unreachable    
}

define cc 10 %actor* @actor_new(%config* %cfg, %behavior* %beh) inlinehint {
    ; return config_create(cfg, sizeof(ACTOR), beh);
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %a = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 1, %behavior* %beh)
    ret %actor* %a
}
define cc 10 %actor* @value_new(%config* %cfg, %behavior* %beh, %any %data) inlinehint {
    ; Value v = (Value)config_create(cfg, sizeof(VALUE), beh);
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %v.1 = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 2, %behavior* %beh)
    ; DATA(v) = data;
    ; #define DATA(v)     (((Value)(v))->data)
    %v.2 = bitcast %actor* %v.1 to %value*
    %v.data = getelementptr inbounds %value* %v.2, i32 0, i32 1
    store %any %data, %any* %v.data, align 1
    ; return (Actor)v;
    ret %actor* %v.1
}
define cc 10 %actor* @serial_with_value(%config* %cfg, %actor* %v) inlinehint {
    ; Serial s = (Serial)config_create(cfg, sizeof(SERIAL), act_serial);
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %s.1 = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 3, %behavior* @act_serial)
    ; s->current_behavior = v; // an "unseralized" behavior actor
    %s.2 = bitcast %actor* %s.1 to %serial*
    %s.current_behavior = getelementptr inbounds %serial* %s.2, i32 0, i32 1
    store %actor* %v, %actor** %s.current_behavior
    ; return (Actor)s;
    ret %actor* %s.1
}
define cc 10 %actor* @serial_new(%config* %cfg, %behavior* %beh, %any %data) inlinehint {
    ; return serial_with_value(cfg, value_new(cfg, beh, data));
    %v = tail call cc 10 %actor* @value_new(%config* %cfg, %behavior* %beh, %any %data)
    %s = tail call cc 10 %actor* @serial_with_value(%config* %cfg, %actor* %v)
    ret %actor* %s
}

@.str.serialized_actor_required = private unnamed_addr constant [40 x i8] c"actor_become: serialized actor required\00", align 1
define cc 10 void @actor_become(%actor* %s, %actor* %v) inlinehint {
    ; if (act_serial != BEH(s)) { halt("actor_become: serialized actor required"); }
    ; #define BEH(a)      (((Actor)(a))->beh)
    %s.beh.fpp = getelementptr inbounds %actor* %s, i32 0, i32 0
    %s.beh.fptr = load %behavior** %s.beh.fpp, align 8
    %beh_not_equal = icmp ne %behavior* @act_serial, %s.beh.fptr
    br i1 %beh_not_equal, label %halt, label %proceed 

proceed:
    ; ((Serial)s)->beh_1 = v; // remember "behavior" for later commit
    %serial = bitcast %actor* %s to %serial*
    %serial.beh_next.pp = getelementptr inbounds %serial* %serial, i32 0, i32 2
    store %actor* %v, %actor** %serial.beh_next.pp
    ret void

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([40 x i8]* @.str.serialized_actor_required, i32 0, i32 0))
    unreachable
}
define cc 10 void @act_serial(%event* %e) {
    ; Serial s = (Serial)SELF(e);
    ; #define SELF(e)     (((Event)(e))->target)
    %self.pp = getelementptr inbounds %event* %e, i32 0, i32 2
    %self.ptr = load %actor** %self.pp
    %s = bitcast %actor* %self.ptr to %serial*
    ; s->beh_next = s->beh_current; // default behavior for next event
    %s.beh_current.pp = getelementptr inbounds %serial* %s, i32 0, i32 1
    %s.beh_current.ptr = load %actor** %s.beh_current.pp
    %s.beh_next.pp = getelementptr inbounds %serial* %s, i32 0, i32 2
    %s.beh_next.ptr = load %actor** %s.beh_next.pp ; need to cache this here
    store %actor* %s.beh_current.ptr, %actor** %s.beh_next.pp
    ; (CODE(s->beh_current))(e);  // INVOKE CURRENT SERIALIZED BEHAVIOR
    ; #define CODE(v)     BEH(v)
    ; #define BEH(a)      (((Actor)(a))->beh)
    %beh.fpp = getelementptr inbounds %actor* %s.beh_current.ptr, i32 0, i32 0
    %beh.fptr = load %behavior** %beh.fpp
    tail call cc 10 void %beh.fptr(%event* %e)
    ; s->beh_current = s->beh_next;  // commit behavior change (if any)
    store %actor* %s.beh_next.ptr, %actor** %s.beh_current.pp
    ret void
}

define cc 10 void @beh_event(%event* %e) {
    ; TODO: implement
    ret void
}
@.str.config_actor_required = private unnamed_addr constant [33 x i8] c"event_new: config actor required\00", align 1
define cc 10 %actor* @event_new(%config* %cfg, %actor* %target, %actor* %msg) inlinehint {
    ; if (beh_config != BEH(cfg)) { halt("event_new: config actor required"); }
    ; #define BEH(a)      (((Actor)(a))->beh)
    %cfg.a = bitcast %config* %cfg to %actor*
    %cfg.a.beh.fpp = getelementptr inbounds %actor* %cfg.a, i32 0, i32 0
    %cfg.a.beh.fptr = load %behavior** %cfg.a.beh.fpp, align 8
    %beh_not_equal = icmp ne %behavior* @beh_config, %cfg.a.beh.fptr
    br i1 %beh_not_equal, label %halt, label %proceed

proceed:
    ; Event e = (Event)config_create(cfg, sizeof(EVENT), beh_event);
    ; #define config_create(cfg, size, beh)   (((cfg)->create)((cfg), (size), (beh)))
    %cfg.create.fpp = getelementptr inbounds %config* %cfg, i32 0, i32 2
    %cfg.create.fptr = load %create** %cfg.create.fpp, align 8
    %e.1 = tail call cc 10 %actor* %cfg.create.fptr(%config* %cfg, i64 4, %behavior* @beh_event)
    ; e->sponsor = cfg;
    %e.2 = bitcast %actor* %e.1 to %event*
    %e.sponsor = getelementptr inbounds %event* %e.2, i32 0, i32 1
    store %config* %cfg, %config** %e.sponsor
    ; e->target = target;
    %e.target = getelementptr inbounds %event* %e.2, i32 0, i32 2
    store %actor* %target, %actor** %e.target
    ; e->message = msg;
    %e.message = getelementptr inbounds %event* %e.2, i32 0, i32 3
    store %actor* %msg, %actor** %e.message
    ; return (Actor)e;
    ret %actor* %e.1

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([33 x i8]* @.str.config_actor_required, i32 0, i32 0))
    unreachable
}

define cc 10 void @beh_config(%event* %e) {
    ; TODO: implement
    ret void
}
@.str.root_config_fail = private unnamed_addr constant [18 x i8] c"root_config_fail!\00", align 1
define internal cc 10 void @root_config_fail(%config* %cfg, %actor* %reason) inlinehint {
    ; halt("root_config_fail!");
    tail call cc 10 void @halt(i8* getelementptr inbounds ([18 x i8]* @.str.root_config_fail, i32 0, i32 0))
    ret void
}
define internal cc 10 %actor* @root_config_create(%config* %cfg, i64 %n_bytes, %behavior* %beh) {
    ; Actor a = ALLOC(n_bytes)
    ; #define ALLOC(S)    (calloc((S), 1))
    %a.1 = call noalias i8* @calloc(i64 %n_bytes, i64 1)
    %a.2 = bitcast i8* %a.1 to %actor*
    ; BEH(a) = beh;
    ; #define BEH(a)      (((Actor)(a))->beh)
    %a.beh.fpp = getelementptr inbounds %actor* %a.2, i32 0, i32 0
    store %behavior* %beh, %behavior** %a.beh.fpp, align 8
    ; return a;
    ret %actor* %a.2
}
define internal cc 10 void @root_config_destroy(%config* %cfg, %actor* %victim) inlinehint {
    ; FREE(victim)
    ; #define FREE(p)     ((p) = (free(p), NULL))
    %victim.ptr = bitcast %actor* %victim to i8*
    call void @free(i8* %victim.ptr)
    ret void
}
define internal cc 10 void @root_config_send(%config* %cfg, %actor* %target, %actor* %msg) inlinehint {
    ; config_enqueue(cfg, event_new(cfg, target, msg));
    ; #define         config_enqueue(cfg, e)          (deque_give((cfg), (cfg)->events, (e)))
    %e = tail call cc 10 %actor* @event_new(%config* %cfg, %actor* %target, %actor* %msg)
    %cfg.events.pp = getelementptr inbounds %config* %cfg, i32 0, i32 5
    %cfg.events.ptr = load %actor** %cfg.events.pp, align 8
    tail call cc 10 void @deque_give(%config* %cfg, %actor* %cfg.events.ptr, %actor* %e)
    ret void
}
define cc 10 %config* @config_new() {
    ; Config cfg = NEW(CONFIG)
    ; #define NEW(T)      ((T *)calloc(sizeof(T), 1))
    %cfg.1 = call noalias i8* @calloc(i64 6, i64 1)
    %cfg.2 = bitcast i8* %cfg.1 to %config*
    ; BEH(cfg) = beh_config;
    ; #define BEH(a)      (((Actor)(a))->beh)
    %cfg.a = bitcast %config* %cfg.2 to %actor*
    %cfg.a.beh.fpp = getelementptr inbounds %actor* %cfg.a, i32 0, i32 0
    store %behavior* @beh_config, %behavior** %cfg.a.beh.fpp, align 8
    ; cfg->fail = root_config_fail; // error reporting procedure
    %cfg.fail.fpp = getelementptr inbounds %config* %cfg.2, i32 0, i32 1
    store %fail* @root_config_fail, %fail** %cfg.fail.fpp, align 8
    ; cfg->create = root_config_create; // actor creation procedure
    %cfg.create.fpp = getelementptr inbounds %config* %cfg.2, i32 0, i32 2
    store %create* @root_config_create, %create** %cfg.create.fpp, align 8
    ; cfg->destroy = root_config_destroy; // reclaim actor resources
    %cfg.destroy.fpp = getelementptr inbounds %config* %cfg.2, i32 0, i32 3
    store %destroy* @root_config_destroy, %destroy** %cfg.destroy.fpp, align 8
    ; cfg->send = root_config_send; // event creation procedure
    %cfg.send.fpp = getelementptr inbounds %config* %cfg.2, i32 0, i32 4
    store %send* @root_config_send, %send** %cfg.send.fpp, align 8
    ; cfg->events = deque_new(cfg);
    %cfg.events = getelementptr inbounds %config* %cfg.2, i32 0, i32 5
    %deque = tail call cc 10 %actor* @deque_new(%config* %cfg.2)
    store %actor* %deque, %actor** %cfg.events, align 8
    ; return cfg;
    ret %config* %cfg.2
}
@.str.config_dequeue_config_required = private unnamed_addr constant [38 x i8] c"config_dequeue: config actor required\00", align 1
define cc 10 %actor* @config_dequeue(%config* %cfg) inlinehint {
    ; if (beh_config != BEH(cfg)) { halt("config_dequeue: config actor required"); }
    ; #define BEH(a)      (((Actor)(a))->beh)
    %cfg.a = bitcast %config* %cfg to %actor*
    %cfg.a.beh.fpp = getelementptr inbounds %actor* %cfg.a, i32 0, i32 0
    %cfg.a.beh.fptr = load %behavior** %cfg.a.beh.fpp, align 8
    %beh_not_equal = icmp ne %behavior* @beh_config, %cfg.a.beh.fptr
    br i1 %beh_not_equal, label %halt, label %proceed

proceed:
    ; if (deque_empty_p(cfg, cfg->events) != a_false)
    ; #define a_false ((Actor)(&the_false_actor))
    %cfg.events.pp = getelementptr inbounds %config* %cfg, i32 0, i32 5
    %cfg.events.ptr = load %actor** %cfg.events.pp, align 8
    %empty_check_result = tail call cc 10 %actor* @deque_empty_p(%config* %cfg, %actor* %cfg.events.ptr)
    %is_not_empty = icmp eq %actor* %empty_check_result, @the_false_actor
    br i1 %is_not_empty, label %take, label %shortcircuit    

take:
    %a = tail call cc 10 %actor* @deque_take(%config* %cfg, %actor* %cfg.events.ptr)
    ret %actor* %a 

shortcircuit:
    ret %actor* bitcast(%value* @the_halt_actor to %actor*)

halt:
    tail call cc 10 void @halt(i8* getelementptr inbounds ([38 x i8]* @.str.config_dequeue_config_required, i32 0, i32 0))
    unreachable    
}
define cc 10 %actor* @config_dispatch(%config* %cfg) inlinehint {
    ; Actor a = config_dequeue(cfg);
    %a = tail call cc 10 %actor* @config_dequeue(%config* %cfg)
    ; if (beh_event == BEH(a))
    ; #define BEH(a)      (((Actor)(a))->beh)
    %a.beh.fpp = getelementptr inbounds %actor* %a, i32 0, i32 0
    %a.beh.fptr = load %behavior** %a.beh.fpp, align 8
    %beh_equal = icmp eq %behavior* @beh_event, %a.beh.fptr 
    br i1 %beh_equal, label %proceed, label %finalize

proceed:
    ; Event e = (Event)a
    %e = bitcast %actor* %a to %event*
    ; (CODE(SELF(e)))(e); // INVOKE ACTION PROCEDURE 
    ; #define CODE(v)     BEH(v)
    ; #define BEH(a)      (((Actor)(a))->beh)
    ; #define SELF(e)     (((Event)(e))->target)
    %self.pp = getelementptr inbounds %event* %e, i32 0, i32 2
    %self.ptr = load %actor** %self.pp, align 8
    %beh.fpp = getelementptr inbounds %actor* %self.ptr, i32 0, i32 0
    %beh.fptr = load %behavior** %beh.fpp, align 8
    tail call cc 10 void %beh.fptr(%event* %e)
    br label %finalize

finalize:
    ret %actor* %a
}

define internal cc 10 void @comb_true(%event* %e) {
    ; TODO: implement
    ret void
}
define internal cc 10 void @comb_false(%event* %e) {
    ; TODO: implement
    ret void
}

@.str.tart_unit_tests = private unnamed_addr constant [28 x i8] c"---- actor unit tests ----\0A\00", align 1
@.str.NIL_eq = private unnamed_addr constant [10 x i8] c"NIL = %p\0A\00", align 1
@.str.NOTHING_eq = private unnamed_addr constant [14 x i8] c"NOTHING = %p\0A\00", align 1
@.str.a_halt_eq = private unnamed_addr constant [13 x i8] c"a_halt = %p\0A\00", align 1
@.str.a_ignore_eq = private unnamed_addr constant [15 x i8] c"a_ignore = %p\0A\00", align 1
define void @run_tests() #2 {
    %stderr = load %struct._IO_FILE** @stderr, align 8
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([28 x i8]* @.str.tart_unit_tests, i32 0, i32 0))
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([10 x i8]* @.str.NIL_eq, i32 0, i32 0), i8* bitcast(%pair* @the_nil_pair_actor to i8*))
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([14 x i8]* @.str.NOTHING_eq, i32 0, i32 0), i8* bitcast(%value* @the_halt_actor to i8*))
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([13 x i8]* @.str.a_halt_eq, i32 0, i32 0), i8* bitcast(%value* @the_halt_actor to i8*))
    call i32 (%struct._IO_FILE*, i8*, ...)* @fprintf(%struct._IO_FILE* %stderr, i8* getelementptr inbounds ([15 x i8]* @.str.a_ignore_eq, i32 0, i32 0), i8* bitcast(%actor* @the_ignore_actor to i8*))
    ret void
}

define i32 @main() #2 {
    call void @run_tests()
    ret i32 0
}

; TODO: consider instead of making these all functions with a calling convention
;       to instead put them all within a void run() and use labels for moving
;       around

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf"="true" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }