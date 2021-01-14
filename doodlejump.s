#####################################################################
#
# CSC258H5S fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Morgan Chang, 1005127113
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 5
#
# Which approved additional features have been implemented?
# Miletone 4:
# 1. Display score board
# 2. Game over / Retry
# Milestone 5:
# 3. Dynamic on-screen notifications: "Good", "Nice", "Wow"
# 4. Fancier graphics: Start / Game Over screen, move doodler's face direction as direction changes
# 5. Speed up jump rate according sleep length
# 6. Short platform type
#
#####################################################################

.data

	# Game Controls
	# j - move to the left  - 106
	# k - move to the right - 107
	# s - start / restart   - 115

	# Global Settings
	screenLength: 		.word   32
	jumpHeight:    		.word   -10
	fallHeight:		.word	1
	pause:			.word	150
	
	# Colors
	backgroundColor:	.word	0xfffde7	 	
	doodlerColor:		.word	0x98b4d4
	doodlerPantsColor:	.word	0x2d68c4	
	platformColor:		.word	0x7dd0b6	
	targetPlatformColor:  	.word 	0xa0d1ca
	wordColor:		.word	0x584b4b	
	illegalArea:    	.word   0x000000
	
	# Doodler Settings
	doodlerX:		.word	12
	doodlerY:		.word	25
	newDoodlerX:		.word	12
	newDoodlerY:		.word	25
	previousDirection: 	.word   0
	
	# Platform Settings
	topPlatformX:		.word   10
	topPlatformY:		.word   14
	newTopPlatformX:	.word   10
	newTopPlatformY:	.word   14
	
	middlePlatformX:	.word   20
	middlePlatformY:	.word   22
	newMiddlePlatformX:	.word   20
	newMiddlePlatformY:	.word   22
	
	bottomPlatformX:	.word   10
	bottomPlatformY:	.word   30
	newBottomPlatformX:	.word   10
	newBottomPlatformY:	.word   30
	
	topPlatformType:	.word 0 
	middlePlatformType: 	.word 0 
	bottomPlatformType: 	.word 0 
	
	# Illegal Area Settings
	illegalAreaX:		.word 	0
	illegalAreaY: 		.word 	32
	
	# Game Over Settings
	G1X: 			.word 11
	G2X: 			.word 16
	GY: 			.word 6
	
	# Score variables
	scoreTens:		.word 0
	scoreTensX: 		.word 24
	scoreDigits: 		.word 0
	scoreDigitsX: 		.word 28
	scoreY: 		.word 1
	
.text

startScreen:
	lw $a0, screenLength
	lw $a1, backgroundColor
	mul $a2, $a0, $a0
	mul $a2, $a2, 4 
	add $a2, $a2, $gp 
	add $a0, $gp, $zero
	
startScreenBackgroundLoop:
	beq $a0, $a2, drawPressSToStart
	sw $a1, 0($a0) 
	addiu $a0, $a0, 4
	j startScreenBackgroundLoop	

checkStartInput:
	lw $s3, 0xffff0000
	bne $s3, 1, checkStartInput
	j fetchStartInput
	
	fetchStartInput:
		lw $s4, 0xffff0004
		bne $s4, 115, checkStartInput
		j start
	
start:
	lw $a0, screenLength
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 
	mul $a2, $a2, 4 
	add $a2, $a2, $gp 
	add $a0, $gp, $zero
	
mainBackgroundLoop:
	beq $a0, $a2, main
	sw $a1, 0($a0) 
	addiu $a0, $a0, 4
	j mainBackgroundLoop	

main:
	li $v1, 0 # store doodler direction
	
	# draw illegal area
	add $t3, $zero, $zero
	lw $a0, illegalAreaX
	lw $a1, illegalAreaY
	jal getCoordinates
	jal drawillegalArea
	
	# sleep
	lw $a0, pause
	jal sleep
		
	# erase the old doodler
	lw $a0, doodlerX
	lw $a1, doodlerY
	jal getCoordinates
	jal eraseDoodler
	
	# get new position of the doodler
	lw $a0, newDoodlerX
	lw $a1, newDoodlerY
	jal getCoordinates
	
	# Terminate program if doodler jumps to illegal area
	lw $t3, illegalArea
	lw $t4, 256($a0)
	beq $t3, $t4, exit
	
	jal checkUserinput
	jal moveDoodler
	
checkJumpToTarget:
	# check if doodler gets to top platform
	lw $t3, targetPlatformColor
	lw $t4, 384($a0)
	beq $t3, $t4, updatePlatformPosition
	lw $t4, 392($a0)
	beq $t3, $t4, updatePlatformPosition

moveDownScreen:	
	# move down screen
	li $t5, 29
	lw $a1, bottomPlatformY
	ble $a1, $t5, moveDownPlatform
	
# erase the old platforms
continue:
	lw $a0, topPlatformX
	lw $a1, topPlatformY
	jal getCoordinates
	jal erasePlatform
	
	lw $a0, middlePlatformX
	lw $a1, middlePlatformY
	jal getCoordinates
	jal erasePlatform
	
	lw $a0, bottomPlatformX
	lw $a1, bottomPlatformY
	jal getCoordinates
	jal erasePlatform
	
	# draw and store values of the new platforms 
	lw $t1, targetPlatformColor
	lw $t7, topPlatformType
	lw $a1, newTopPlatformY
	lw $a0, newTopPlatformX
	sw $a1, topPlatformY
	sw $a0, topPlatformX
	jal getCoordinates
	bne $t7, 1, drawPlatform
	drawShortTopPlatform:
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
	
drawMiddleBottomPlatform:
	lw $t7, middlePlatformType
	lw $a1, newMiddlePlatformY
	lw $a0, newMiddlePlatformX
	sw $a1, middlePlatformY
	sw $a0, middlePlatformX
	jal getCoordinates
	lw $t1, platformColor
	bne $t7, 1, drawMiddlePlatform
	drawShortMiddlePlatform:
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
drawNextPlatform:
	lw $a1, newBottomPlatformY
	lw $a0, newBottomPlatformX
	sw $a1, bottomPlatformY
	sw $a0, bottomPlatformX
	jal getCoordinates
	lw $t1, platformColor
	lw $t7, bottomPlatformType
	bne $t7, 1, drawBottomPlatform
	drawShortBottomPlatform:
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		
	jal drawDynamicNotifications

drawNewDoodler:
	# draw the new doodler
	lw $a0, newDoodlerX
	lw $a1, newDoodlerY
	jal getCoordinates
	jal drawDoodler
	
fall:
	lw $t0, newDoodlerX
	lw $t1, newDoodlerY
	sw $t0, doodlerX
	sw $t1, doodlerY
	lw $t3, fallHeight
	add $t1, $t1, $t3
	sw $t1, newDoodlerY

	j main

jump:
	lw $t0, newDoodlerX
	lw $t1, newDoodlerY
	sw $t0, doodlerX
	sw $t1, doodlerY
	lw $t3, jumpHeight
	add $t1, $t1, $t3
	sw $t1, newDoodlerY
	
	j main
	
#####################################################################
# FUNCTIONS
#####################################################################

moveDownPlatform:
	lw $a1, middlePlatformY
	addiu $a1, $a1, 1
	sw $a1, newMiddlePlatformY

	lw $a1, topPlatformY
	addiu $a1, $a1, 1
	sw $a1, newTopPlatformY

	lw $a1, bottomPlatformY
	addiu $a1, $a1, 1
	sw $a1, newBottomPlatformY

	jal increaseScore

updatePlatformPosition:
	lw $a1, middlePlatformY
	lw $a0, middlePlatformX
	addiu $a1, $a1, 5
	sw $a1, newBottomPlatformY
	sw $a0, newBottomPlatformX
	
	lw $a1, topPlatformY
	lw $a0, topPlatformX
	addiu $a1, $a1, 5
	sw $a1, newMiddlePlatformY
	sw $a0, newMiddlePlatformX
		
	jal randomIntY # $a0 = rand int
	addiu $a0, $a0, 5
	lw $t6, newMiddlePlatformY
	subu $t6, $t6, $a0 
	sw $t6, newTopPlatformY
		
	jal randomIntX # $a0 = rand int
	sw $a0, newTopPlatformX
	
	lw $t7, scoreTens
	bge $t7, 2, morePlatformTypes
	
	jal continue
	
morePlatformTypes:
	lw $t7, middlePlatformType
	sw $t7, bottomPlatformType
	
	lw $t7, topPlatformType
	sw $t7, middlePlatformType
	
	jal randomIntPlatformType
	sw $a0, topPlatformType
	jal continue

# a0 = adress of position at bitmap display
drawBottomPlatform:
	lw $t1, platformColor
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, 16($a0)
	sw $t1, 20($a0)
	sw $t1, 24($a0)
	sw $t1, 28($a0)
	jal drawDynamicNotifications
	
drawMiddlePlatform:
	lw $t1, platformColor
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, 16($a0)
	sw $t1, 20($a0)
	sw $t1, 24($a0)
	sw $t1, 28($a0)
	j drawNextPlatform
	
drawPlatform:
	lw $t1, targetPlatformColor
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, 16($a0)
	sw $t1, 20($a0)
	sw $t1, 24($a0)
	sw $t1, 28($a0)
	j drawMiddleBottomPlatform

drawShortPlatform:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	j terminate
	
erasePlatform:
	lw $t1, backgroundColor
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, 16($a0)
	sw $t1, 20($a0)
	sw $t1, 24($a0)
	sw $t1, 28($a0)
	jr $ra

drawDoodler:
	lw $t1, doodlerPantsColor
	sw $t1, 128($a0)
	sw $t1, 132($a0)
	sw $t1, 136($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	lw $t1, doodlerColor
	sw $t1, -124($a0)
	sw $t1, -128($a0)
	sw $t1, -120($a0)
	sw $t1, 0($a0)
        sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	beq $v1, 0, drawDoolerPreviousDirection
	beq $v1, 1, drawDoodlerRight
	beq $v1, 2, drawDoodlerLeft

	checkHitsPlatform:
	# jump if doodler hits a platform
		lw $t3, platformColor
		lw $t4, 384($a0)
		beq $t3, $t4, jump
		lw $t4, 392($a0)
		beq $t3, $t4, jump
		lw $t3, targetPlatformColor
		lw $t4, 384($a0)
		beq $t3, $t4, jump
		lw $t4, 392($a0)
		beq $t3, $t4, jump
	
		jr $ra
		
	drawDoolerPreviousDirection:
		lw $t7, previousDirection
		beq $t7, 0, drawDoodlerRight
		beq $t7, 1, drawDoodlerRight
		beq $t7, 2, drawDoodlerLeft
		j checkHitsPlatform
	
	drawDoodlerRight:
		sw $t1, 12($a0)
		j checkHitsPlatform
	drawDoodlerLeft:
		sw $t1, -4($a0)
		j checkHitsPlatform
	
eraseDoodler:
	lw $t1, backgroundColor
	sw $t1, 128($a0)
	sw $t1, 132($a0)
	sw $t1, 136($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	sw $t1, -124($a0)
	sw $t1, -128($a0)
	sw $t1, -120($a0)
	sw $t1, 0($a0)
        sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, -256($a0)
	sw $t1, 12($a0)
	sw $t1, -4($a0)
	jr $ra
	
# change doodler direction
moveDoodler:
	beq $v1, 0, terminate
	beq $v1, 1, moveRight
	beq $v1, 2, moveLeft
	j terminate

	moveRight:
		lw $t0, newDoodlerX
		lw $t1, newDoodlerY
		sw $t0, doodlerX
		sw $t1, doodlerY
		add $t0, $t0, 4
		sw $t0, newDoodlerX
		sw $t1, newDoodlerY
		j terminate
	
	moveLeft:
		lw $t0, newDoodlerX
		lw $t1, newDoodlerY
		sw $t0, doodlerX
		sw $t1, doodlerY
		sub $t0, $t0, 4
		sw $t0, newDoodlerX
		sw $t1, newDoodlerY
		j terminate
	
checkUserinput:
	lw $s3, 0xffff0000
	beq $s3, 1, keyboardInput
	j terminate
	
	keyboardInput:
		lw $s4, 0xffff0004
		beq $s4, 107, setRight
		beq $s4, 106, setLeft
		j terminate
	
		setRight:
			li $v1, 1
			sw $v1, previousDirection
			j terminate
	
		setLeft:
			li $v1, 2
			sw $v1, previousDirection
			j terminate
			
# reset .data
restart:
	li $a0, 0
	sw $a0, scoreTens
	sw $a0, scoreDigits
	sw $a0, previousDirection
	sw $a0, topPlatformType
	sw $a0, middlePlatformType
	sw $a0, bottomPlatformType

	li $a0, 12
	sw $a0, newDoodlerX
	sw $a0, doodlerX
	li $a0, 25
	sw $a0, newDoodlerY
	sw $a0, doodlerY
	
	li $a0, 10
	sw $a0, topPlatformX
	sw $a0, newTopPlatformX
	li $a0, 14
	sw $a0, topPlatformY
	sw $a0, newTopPlatformY
	
	li $a0, 20
	sw $a0, middlePlatformX
	sw $a0, newMiddlePlatformX
	li $a0, 22
	sw $a0, middlePlatformY
	sw $a0, newMiddlePlatformY
	
	li $a0, 10
	sw $a0, bottomPlatformX
	sw $a0, newBottomPlatformX
	li $a0, 30
	sw $a0, bottomPlatformY
	sw $a0, newBottomPlatformY
	
	jal checkStartInput
	
drawillegalArea:
	lw $s0, screenLength
	lw $s1, illegalArea
	beq $t3, $s0, terminate
	sw $s1, 0($a0)
	add $t3, $t3, 1
	addiu $a0, $a0, 4
	j drawillegalArea
	
drawGameOver:
	lw $t1, wordColor
	
	lw $a0, G1X
	lw $a1, GY
	jal getCoordinates
	jal drawG
	
	lw $a0, G2X
	lw $a1, GY
	jal getCoordinates
	jal drawG
	
	li $a0, 1
	li $a1, 17
	jal getCoordinates
	jal drawP
	
	li $a0, 5
	li $a1, 17
	jal getCoordinates
	jal drawR
	
	li $a0, 9
	li $a1, 16
	jal getCoordinates
	jal drawE
	
	li $a0, 12
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 15
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 20
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 25
	li $a1, 17
	jal getCoordinates
	jal drawT
	
	li $a0, 28
	li $a1, 17
	jal getCoordinates
	jal drawO
	
	li $a0, 5
	li $a1, 24
	jal getCoordinates
	jal drawR
	
	li $a0, 9
	li $a1, 23
	jal getCoordinates
	jal drawE
	
	li $a0, 12
	li $a1, 24
	jal getCoordinates
	jal drawS
	
	li $a0, 15
	li $a1, 24
	jal getCoordinates
	jal drawT
	
	li $a0, 18
	li $a1, 24
	jal getCoordinates
	jal drawA
	
	li $a0, 22
	li $a1, 24
	jal getCoordinates
	jal drawR
	
	li $a0, 25
	li $a1, 24
	jal getCoordinates
	jal drawT
	
	jal drawScore
	
drawScore:	
	lw $t7, scoreTens
	lw $a0, scoreTensX
	lw $a1, scoreY
	jal getCoordinates
	jal drawNumber
	
	lw $t7, scoreDigits
	lw $a0, scoreDigitsX
	lw $a1, scoreY
	jal getCoordinates
	jal drawNumber
	
	jal restart
	
drawNumber:
	beq $t7, 0, draw0
	beq $t7, 1, draw1
	beq $t7, 2, draw2
	beq $t7, 3, draw3
	beq $t7, 4, draw4
	beq $t7, 5, draw5
	beq $t7, 6, draw6
	beq $t7, 7, draw7
	beq $t7, 8, draw8
	beq $t7, 9, draw9
	
	j terminate

# a0 = sleep length
sleep:
	li $v0, 32
	syscall
	jr $ra

# return a0 = random int
randomIntY:
	li $v0, 42
	li $a0, 0
	li $a1, 4
    	syscall

	jr $ra
	
# return a0 = random int
randomIntX:
	li $v0, 42
	li $a0, 0
	li $a1, 24
    	syscall
	jr $ra
	
# return a0 = random int
randomIntPlatformType:
	li $v0, 42
	li $a0, 0
	li $a1, 2
    	syscall
	jr $ra
	
# a0 = x-axis
# a1 = y-axis
# returns a0 = the adress for bitmap display
getCoordinates:
	lw $v0, screenLength
	mul $v0, $v0, $a1	# multiply by y position
	add $v0, $v0, $a0	# add x position
	mul $v0, $v0, 4		# multiply by 4
	add $v0, $v0, $gp	# add display address
	move $a0, $v0
	jr $ra 
	
exit:
	lw $a0, screenLength
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 
	mul $a2, $a2, 4 
	add $a2, $a2, $gp 
	add $a0, $gp, $zero
	
exitBackgroundLoop:
	beq $a0, $a2, drawGameOver
	sw $a1, 0($a0) 
	addiu $a0, $a0, 4
	j exitBackgroundLoop

quitProgram:
	li $v0, 10
	syscall

terminate:
	jr $ra
	
drawG:
	sw $t1,	0($a0)
	sw $t1,	4($a0)
	sw $t1,	124($a0)
	sw $t1,	252($a0)
	sw $t1,	380($a0)
	sw $t1,	512($a0)
	sw $t1,	516($a0)
	sw $t1,	388($a0)
	sw $t1,	392($a0)
	j terminate
	
drawP:
	sw $t1,	0($a0)
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	256($a0)
	sw $t1,	384($a0)
	sw $t1,	136($a0)
	sw $t1,	260($a0)
	j terminate

drawR:
	sw $t1,	0($a0)
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	256($a0)
	sw $t1,	136($a0)
	sw $t1,	260($a0)
	sw $t1,	384($a0)
	sw $t1,	392($a0)
	j terminate
	
drawE:
	sw $t1,	0($a0)
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	256($a0)
	sw $t1,	260($a0)
	sw $t1,	384($a0)
	sw $t1,	512($a0)
	sw $t1,	516($a0)
	j terminate
	
drawS:
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	260($a0)
	sw $t1,	388($a0)
	sw $t1,	384($a0)
	j terminate
	
drawT:
	sw $t1,	0($a0)
	sw $t1,	4($a0)
	sw $t1,	8($a0)
	sw $t1,	132($a0)
	sw $t1,	260($a0)
	sw $t1,	388($a0)
	j terminate
	
drawO:
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	256($a0)
	sw $t1,	388($a0)
	sw $t1,	264($a0)
	sw $t1,	136($a0)
	j terminate

drawA:
	sw $t1,	4($a0)
	sw $t1,	128($a0)
	sw $t1,	136($a0)
	sw $t1,	256($a0)
	sw $t1,	264($a0)
	sw $t1,	260($a0)
	sw $t1,	384($a0)
	sw $t1,	392($a0)
	j terminate
	
drawD:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 388($a0)
	sw $t1, 384($a0)
	sw $t1, 256($a0)
	sw $t1, 128($a0)
	j terminate

drawW:
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	sw $t1, 260($a0)
	sw $t1, 268($a0)
	sw $t1, 144($a0)
	sw $t1, 16($a0)
	j terminate

drawPressSToStart:
	lw $t1, wordColor
	
	li $a0, 1
	li $a1, 17
	jal getCoordinates
	jal drawP
	
	li $a0, 5
	li $a1, 17
	jal getCoordinates
	jal drawR
	
	li $a0, 9
	li $a1, 16
	jal getCoordinates
	jal drawE
	
	li $a0, 12
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 15
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 20
	li $a1, 17
	jal getCoordinates
	jal drawS
	
	li $a0, 25
	li $a1, 17
	jal getCoordinates
	jal drawT
	
	li $a0, 28
	li $a1, 17
	jal getCoordinates
	jal drawO
	
	li $a0, 7
	li $a1, 24
	jal getCoordinates
	jal drawS
	
	li $a0, 10
	li $a1, 24
	jal getCoordinates
	jal drawT
	
	li $a0, 13
	li $a1, 24
	jal getCoordinates
	jal drawA
	
	li $a0, 17
	li $a1, 24
	jal getCoordinates
	jal drawR
	
	li $a0, 20
	li $a1, 24
	jal getCoordinates
	jal drawT
	
	jal checkStartInput
	
increaseScore:
	# increase scoreDigits
	lw $t7, scoreDigits
	addiu $t7, $t7, 1
	sw $t7, scoreDigits
	bne $t7, 10, continue
		# increase scoreTens
		sw $zero, scoreDigits
		lw $t7, scoreTens
		addiu $t7, $t7, 1
		sw $t7, scoreTens
		# speed up jump rate as score increases
		beq $t7, 2, speedUpJumpRateGE20
		beq $t7, 3, speedUpJumpRateGE30
		beq $t7, 4, speedUpJumpRateGE40
		beq $t7, 5, speedUpJumpRateGE50
		jal continue

	speedUpJumpRateGE20:
		li $t8, 125
		sw $t8, pause
		jal continue
	
	speedUpJumpRateGE30:
		li $t8, 115
		sw $t8, pause
		jal continue
	
	speedUpJumpRateGE40:
		li $t8, 100
		sw $t8, pause
		jal continue

	speedUpJumpRateGE50:
		li $t8, 90
		sw $t8, pause
		jal continue
	
draw0:
	sw $t1, 128($a0)
	sw $t1, 256($a0)
	sw $t1, 388($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 4($a0)
	j terminate
	
draw1:
	sw $t1, 0($a0)
	sw $t1, 132($a0)
	sw $t1, 260($a0)
	sw $t1, 388($a0)
	sw $t1, 4($a0)
	j terminate
	
draw2:
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 260($a0)
	sw $t1, 388($a0)
	sw $t1, 4($a0)
	sw $t1, 392($a0)
	j terminate
	
draw3:
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 260($a0)
	sw $t1, 264($a0)
	sw $t1, 520($a0)
	sw $t1, 516($a0)
	sw $t1, 392($a0)
	sw $t1, 4($a0)
	j terminate
	
draw4:
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 136($a0)
	sw $t1, 392($a0)
	j terminate

draw5:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 128($a0)
	sw $t1, 260($a0)
	sw $t1, 384($a0)
	sw $t1, 388($a0)
	j terminate

draw6:
	sw $t1, 0($a0)
	sw $t1, -124($a0)
	sw $t1, 264($a0)
	sw $t1, 132($a0)
	sw $t1, 128($a0)
	sw $t1, 256($a0)
	sw $t1, 384($a0)
	sw $t1, 388($a0)
	j terminate

draw7:
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 392($a0)
	j terminate
	
draw8:
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	j terminate
	
draw9:
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 392($a0)
	sw $t1, 520($a0)
	j terminate
	
drawDynamicNotifications:
	lw $t7, scoreTens
	beq $t7, 1, drawGood
	beq $t7, 2, drawNice
	bge $t7, 3, drawWow
	j drawNewDoodler
	
drawGood:
	lw $t1, wordColor
	li $a0, 10
	li $a1, 2
	jal getCoordinates
	jal drawG
	add $a0, $a0, 12
	jal drawO
	add $a0, $a0, 16
	jal drawO
	add $a0, $a0, 16
	jal drawD
	jal drawNewDoodler
	
drawNice:
	eraseGood: 
		lw $t1, backgroundColor
		li $a0, 10
		li $a1, 2
		jal getCoordinates
		jal drawG
		add $a0, $a0, 12
		jal drawO
		add $a0, $a0, 16
		jal drawO
		add $a0, $a0, 16
		jal drawD
	
	lw $t1, wordColor
	li $a0, 10
	li $a1, 1
	jal getCoordinates
	sw $t1, 0($a0)
	sw $t1, 12($a0)
	sw $t1, 36($a0)
	sw $t1, 128($a0)
	sw $t1, 132($a0)
	sw $t1, 140($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	sw $t1, 268($a0)
	sw $t1, 384($a0)
	sw $t1, 396($a0)
	sw $t1, 20($a0)
	sw $t1, 148($a0)
	sw $t1, 276($a0)
	sw $t1, 404($a0)
	sw $t1, 28($a0)
	sw $t1, 156($a0)
	sw $t1, 284($a0)
	sw $t1, 412($a0)
	sw $t1, 416($a0)
	sw $t1, 420($a0)
	sw $t1, 32($a0)
	add $a0, $a0, 44
	jal drawE
	
	jal drawNewDoodler
	
drawWow:
	eraseNice: 
		lw $t1, backgroundColor
		li $a0, 10
		li $a1, 1
		jal getCoordinates
			
		sw $t1, 0($a0)
		sw $t1, 12($a0)
		sw $t1, 36($a0)
		sw $t1, 128($a0)
		sw $t1, 132($a0)
		sw $t1, 140($a0)
		sw $t1, 256($a0)
		sw $t1, 264($a0)
		sw $t1, 268($a0)
		sw $t1, 384($a0)
		sw $t1, 396($a0)
		sw $t1, 20($a0)
		sw $t1, 148($a0)
		sw $t1, 276($a0)
		sw $t1, 404($a0)
		sw $t1, 28($a0)
		sw $t1, 156($a0)
		sw $t1, 284($a0)
		sw $t1, 412($a0)
		sw $t1, 416($a0)
		sw $t1, 420($a0)
		sw $t1, 32($a0)
		add $a0, $a0, 44
		jal drawE
	
	lw $t1, wordColor
	li $a0, 9
	li $a1, 2
	jal getCoordinates
	jal drawW
	add $a0, $a0, 24
	jal drawO
	add $a0, $a0, 16
	jal drawW
	
	jal drawNewDoodler
	

