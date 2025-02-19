--
--  Copyright 2021 (C) Jeremy Grosser
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP2040_SVD.Interrupts;
with RP2040_SVD.TIMER;      use RP2040_SVD.TIMER;
with Cortex_M.Hints;
with RP_Interrupts;
with System;

package body RP.Timer.Interrupts is

   procedure IRQ_Handler is
   begin
      TIMER_Periph.INTR.ALARM_2 := True;
   end IRQ_Handler;

   procedure Enable
      (This : in out Delays)
   is
      use RP2040_SVD.Interrupts;
      use System;
   begin
      TIMER_Periph.INTE.ALARM_2 := True;

      RP_Interrupts.Attach_Handler
         (Handler => IRQ_Handler'Access,
          Id      => TIMER_IRQ_2_Interrupt,
          Prio    => Interrupt_Priority'First);
   end Enable;

   procedure Disable
      (This : in out Delays)
   is
   begin
      TIMER_Periph.INTE.ALARM_2 := False;
   end Disable;

   function Enabled
      (This : Delays)
      return Boolean
   is (TIMER_Periph.INTE.ALARM_2);

   procedure Delay_Until
      (This : in out Delays;
       T    : Time)
   is
   begin
      if T <= Clock then
         return;
      end if;
      TIMER_Periph.ALARM2 := UInt32 (T and 16#FFFFFFFF#);
      loop
         Cortex_M.Hints.Wait_For_Interrupt;
         if Clock >= T then
            return;
         elsif TIMER_Periph.INTS.ALARM_2 then
            --  If the high byte of the timer rolled over but we still haven't
            --  reached the target time, reset the alarm and go again
            TIMER_Periph.ALARM2 := UInt32 (T and 16#FFFFFFFF#);
         end if;
      end loop;
   end Delay_Until;

   overriding
   procedure Delay_Microseconds
      (This : in out Delays;
       Us   : Integer)
   is
      Deadline : constant UInt64 := UInt64 (Clock) + UInt64 (Us);
   begin
      if Us > 0 then
         while UInt64 (Clock) < Deadline loop
            null;
         end loop;
      end if;
   end Delay_Microseconds;

   overriding
   procedure Delay_Milliseconds
      (This : in out Delays;
       Ms   : Integer)
   is
   begin
      Delay_Until (This, Clock + (1_000 * Time (Ms)));
   end Delay_Milliseconds;

   overriding
   procedure Delay_Seconds
      (This : in out Delays;
       S    : Integer)
   is
   begin
      Delay_Until (This, Clock + (1_000_000 * Time (S)));
   end Delay_Seconds;
end RP.Timer.Interrupts;
