vHangulCounter EQU $8E40
vHangulDest EQU $8E42
vUploadedTile EQU $8E50
FontInfoTile EQU 8
MaxFontLimit EQU $32
;LegacyFont : Location of Legacy Font
PrintHangul::
	
	;hl(TileMap) bc(Script Bytes), return a : FontBank
	push hl
	push bc
	ld bc,-20
	add hl,bc
	pop bc
	call FindUploadedTiles
	cp a,$FF
	jr nz,.AlreadyExist
	jr .NotFound
.AlreadyExist
	sla a
	add a,$80
	ld [hl],a
	inc a
	pop hl
	ld [hli],a
	ret
.NotFound ;based on http://cafe.naver.com/hansicgu/66
	call FindAvailableTiles
	sla a
		push hl
		ld hl,vUploadedTile

		push af
		
		add a,l
		ld l,a
		
		ld a,b
		call WriteVRAM
		inc hl
		ld a,c
		call WriteVRAM
		pop af
		pop hl
	add a,$80
	ld [hl],a
	pop hl
	inc a
	ld [hli],a
	dec a
	push bc
	ld b,$08
	ld c,a
	ld a,$04
.loop
	sla c
	rl b
	dec a
	jr nz,.loop

		push hl
		ld hl,vHangulDest
		ld a,b
		call WriteVRAM
		inc hl
		ld a,c
		call WriteVRAM
		pop hl
	
	pop bc
	push hl
	call IncreaseCounter
	ld a,b
	and a,$0C
	rrca
	rrca
	add a,$30
	push af ; bank

	
	ld a,b
	and a,$03
	add a,$04
	ld b,a
	ld a,$04
.loop2
	sla c
	rl b
	dec a
	jr nz,.loop2
		push bc
		
			push hl
			ld hl,vHangulDest
			call ReadVRAM
			ld b,a
			inc hl
			call ReadVRAM
			ld c,a
			pop hl
				push bc
				pop hl ; hl : Dest
		
		pop de ;de : Src
	pop af ;bank
	
	ld b,a
	ld c,$2
	call HBlankCopyDouble
	pop hl
	ret
	
PrintEnglish::
	ld b,$00
	ld a,c
	call FindUploadedEnglishTile
	cp a,$FF
	jr nz,.AlreadyExist
	jr .NotFound
.AlreadyExist
	add a,$80
	ld [hli],a
	ret
.NotFound
	call FindAvailableEnglishTile
		push hl
		ld hl,vUploadedTile
		push af
		add a,l
		ld l,a
		ld a,c
		call WriteVRAM
		pop af
		pop hl
	add a,$80
	bit 1,a
	jr z,.DoNotInc
	call IncreaseCounter
.DoNotInc
	push de
	ld [hli],a
	push hl
	push af
	ld a,-$80
	add a,c
	ld hl,$0000
	ld l,a
	add hl,hl
	add hl,hl
	add hl,hl
	push bc
	ld bc,LegacyFont
	add hl,bc
	pop bc
		push hl
		pop de
	pop af
	ld h,$08
	ld l,a
	add hl,hl ;*2
	add hl,hl ;*2
	add hl,hl ;*2
	add hl,hl ;*2 ;귀찮아요...
	ld b,BANK(LegacyFont)
	ld c,$01
	call HBlankCopyDouble
	pop hl
	pop de
	ret
	;hl dest
	;de source
	;a bank	
FindUploadedTiles: ;VRAM : 8DC0~8DFF, bc : Hangul 2bytes, return a : TileNumber
	push de
	push hl
	ld hl,vUploadedTile
	ld e,$10*(FontInfoTile-1)
.loop
	call ReadVRAM
	cp a,b
	jr nz,.PrepareLoop
	inc hl
	call ReadVRAM
	cp a,c
	jr z,.Found
	dec hl
.PrepareLoop
	dec e
	dec e
	jr z,.NotFound
	inc hl
	inc hl
	jr .loop
.Found
	push bc
	ld bc,$FFFF-vUploadedTile+1
	add hl,bc
	pop bc
	ld a,l
	sra a
	
	pop hl
	pop de
	ret
.NotFound
	pop hl
	pop de
	ld a,$FF
	ret
	
FindUploadedEnglishTile ;a : 80~FF a : tile -$80
	push de
	push hl
	ld hl,vUploadedTile
	ld e,$10*(FontInfoTile-1)
	ld d,a
.loop
	call ReadVRAM
	bit 7,a
	jr z,.PrepareLoop
	cp a,d
	jr z,.Found
	inc hl
	call ReadVRAM
	cp a,d
	jr z,.Found
	inc hl
	jr .PrepareLoop2
.PrepareLoop
	inc hl
	inc hl
.PrepareLoop2
	dec e
	dec e
	jr nz,.loop
.NotFound
	pop hl
	pop de
	ld a,$FF
	ret
.Found
	push bc
	ld bc,$FFFF-vUploadedTile+1
	add hl,bc
	ld a,l
	pop bc
	pop hl
	pop de
	ret 
	
FindAvailableTiles:
	push hl
	ld hl,vHangulCounter
	call ReadVRAM
	pop hl
.loop
	push af
	sla a
	add a,$80
	call FindTileMap
	and a
	jr z,.Done
	pop af
	inc a
	cp a,MaxFontLimit
	jr c,.Pass
	ld a,$00
.Pass
	jr .loop
.Done
	pop af
	ret
	
FindAvailableEnglishTile: ; a : Tile return : Tile-$80
	push hl
	ld hl,vHangulCounter
	call ReadVRAM
	sla a
	pop hl
.loop
	push af
	add a,$80
	call FindTileMap
	and a
	jr z,.Done
	pop af
	inc a
	cp a,MaxFontLimit * 2
	jr c,.Pass
	ld a,$00
.Pass
	jr .loop
.Done
	pop af
	ret
	
FindTileMap:
	push bc
	push hl
	ld hl,wTileMap
	ld c,SCREEN_HEIGHT
.loop
	ld b,SCREEN_WIDTH
.loop2
	cp a,[hl]
	jr z,.Found
	inc hl
	dec b
	jr nz,.loop2
	dec c
	jr nz,.loop
	pop hl
	pop bc
.NotFound
	ld a,$00
	ret
.Found
	pop hl
	pop bc
	ld a,$01
	ret
	
IncreaseCounter:
	push af
	push hl
	ld hl,vHangulCounter
	call ReadVRAM
	pop hl
	
	inc a
	cp a,MaxFontLimit
	jr c,.Pass
	ld a,$00
.Pass
	push hl
	ld hl,vHangulCounter
	call WriteVRAM
	pop hl
	pop af
	ret	
ReadVRAM:
	;if LCD is off
	ld a,[rLCDC]
	bit rLCDC_ENABLE,a
	jr z,.ReadMemoryDirectly
.CheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.CheckHBlank
.ReadMemory
	ld a,[hl]
.DoubleCheckHBlank
	push af
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.ReRead
	pop af
	ret
.ReRead
	pop af
	jr .CheckHBlank
.ReadMemoryDirectly
	ld a,[hl]
	ret
	
WriteVRAM:
	;if LCD is off
	push af
	ld a,[rLCDC]
	bit rLCDC_ENABLE,a
	jr z,.WriteMemoryDirectly
.CheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.CheckHBlank
.WriteMemory
	pop af
	ld [hl],a
	push af
.DoubleCheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.ReWrite
	pop af
	ret
.ReWrite
	jr .CheckHBlank
.WriteMemoryDirectly
	pop af
	ld [hl],a
	ret
