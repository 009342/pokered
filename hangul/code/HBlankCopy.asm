HBlankCopyDouble:: 
	ld a,[H_LOADEDROMBANK]
	push af
	ld a,b
	call BankswitchCommon
	ld a,[rLCDC]
	bit rLCDC_ENABLE,a
	sla c
	sla c
	sla c
	jr nz,.LCDOn
.loop ;8bytes : 1
	ld a,[de]
	ld [hli],a
	ld [hli],a
	inc de
	dec c
	jr nz,.loop
	jr .Done
.LCDOn
	;if LCD is on
	ld a,[rSTAT]
	and a,%00000011 
	cp a,$00 ;is H-Blank Period?
	jr z,.LCDOn 
.WaitForHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.WaitForHBlank 
	;Wait For H-Blank Period
.HBlankLoop
	ld a,[de]
	ld [hli],a
	ld [hli],a
.CheckHBlank
	ld a,[rSTAT]
	and a,%00000011 
	cp a,$00 ;is H-Blank Period?
	jr nz,.ReWrite
	
	inc de
	dec c
	jr nz,.HBlankLoop
.Done
	pop af
	call BankswitchCommon
	ret
.ReWrite
	dec hl
	dec hl
	jr .WaitForHBlank
