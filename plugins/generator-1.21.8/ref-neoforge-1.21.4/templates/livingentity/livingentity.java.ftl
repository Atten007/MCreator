<#--
 # MCreator (https://mcreator.net/)
 # Copyright (C) 2012-2020, Pylo
 # Copyright (C) 2020-2024, Pylo, opensource contributors
 # 
 # This program is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public License
 # along with this program.  If not, see <https://www.gnu.org/licenses/>.
 # 
 # Additional permission for code generator templates (*.ftl files)
 # 
 # As a special exception, you may create a larger work that contains part or 
 # all of the MCreator code generator templates (*.ftl files) and distribute 
 # that work under terms of your choice, so long as that work isn't itself a 
 # template for code generation. Alternatively, if you modify or redistribute 
 # the template itself, you may (at your option) remove this special exception, 
 # which will cause the template and the resulting code generator output files 
 # to be licensed under the GNU General Public License without this special 
 # exception.
-->

<#-- @formatter:off -->
<#include "../mcitems.ftl">
<#include "../procedures.java.ftl">

package ${package}.entity;

import net.minecraft.nbt.Tag;
import net.minecraft.network.syncher.EntityDataAccessor;

<#assign extendsClass = "PathfinderMob">
<#assign interfaces = []>

<#if data.aiBase != "(none)">
	<#assign extendsClass = data.aiBase?replace("Enderman", "EnderMan")>
<#else>
	<#assign extendsClass = data.mobBehaviourType?replace("Mob", "Monster")?replace("Creature", "PathfinderMob")>
</#if>

<#if data.breedable>
	<#assign extendsClass = data.tameable?then("TamableAnimal", "Animal")>
</#if>

<#if data.ranged>
	<#assign interfaces += ["RangedAttackMob"]>
</#if>
<#if data.sensitiveToVibration>
	<#assign interfaces += ["VibrationSystem"]>
</#if>

public class ${name}Entity extends ${extendsClass} <#if interfaces?size gt 0>implements ${interfaces?join(",")}</#if> {

	<#if data.mobBehaviourType == "Raider">
	public static final EnumProxy<Raid.RaiderType> RAIDER_TYPE = new EnumProxy<>(Raid.RaiderType.class,
		${JavaModName}Entities.${REGISTRYNAME}, new int[] {0, ${data.raidSpawnsCount[0]}, ${data.raidSpawnsCount[1]}, ${data.raidSpawnsCount[2]}, ${data.raidSpawnsCount[3]}, ${data.raidSpawnsCount[4]}, ${data.raidSpawnsCount[5]}, ${data.raidSpawnsCount[6]}}
	);
	</#if>

	<#list data.entityDataEntries as entry>
		<#if entry.value().getClass().getSimpleName() == "Integer">
			public static final EntityDataAccessor<Integer> DATA_${entry.property().getName()} = SynchedEntityData.defineId(${name}Entity.class, EntityDataSerializers.INT);
		<#elseif entry.value().getClass().getSimpleName() == "Boolean">
			public static final EntityDataAccessor<Boolean> DATA_${entry.property().getName()} = SynchedEntityData.defineId(${name}Entity.class, EntityDataSerializers.BOOLEAN);
		<#elseif entry.value().getClass().getSimpleName() == "String">
			public static final EntityDataAccessor<String> DATA_${entry.property().getName()} = SynchedEntityData.defineId(${name}Entity.class, EntityDataSerializers.STRING);
		</#if>
	</#list>

	<#assign hasPlayableAnimations = false>
	<#list data.animations as animation>
		<#if !animation.walking>
		public final AnimationState animationState${animation?index} = new AnimationState();
		<#assign hasPlayableAnimations = true>
		</#if>
	</#list>

	<#if data.isBoss>
	private final ServerBossEvent bossInfo = new ServerBossEvent(this.getDisplayName(),
		ServerBossEvent.BossBarColor.${data.bossBarColor}, ServerBossEvent.BossBarOverlay.${data.bossBarType});
	</#if>

	<#if data.sensitiveToVibration>
	private final DynamicGameEventListener<VibrationSystem.Listener> dynamicGameEventListener = new DynamicGameEventListener(new VibrationSystem.Listener(this));
	private final VibrationSystem.User vibrationUser = new VibrationUser();
	private VibrationSystem.Data vibrationData = new VibrationSystem.Data();
	</#if>

	public ${name}Entity(EntityType<${name}Entity> type, Level world) {
    	super(type, world);
		xpReward = ${data.xpAmount};
		setNoAi(${(!data.hasAI)});

		<#if data.mobLabel?has_content>
        	setCustomName(Component.literal("${data.mobLabel}"));
        	setCustomNameVisible(true);
        </#if>

		<#if !data.doesDespawnWhenIdle>
			setPersistenceRequired();
        </#if>

		<#if !data.equipmentMainHand.isEmpty()>
        this.setItemSlot(EquipmentSlot.MAINHAND, ${mappedMCItemToItemStackCode(data.equipmentMainHand, 1)});
        </#if>
        <#if !data.equipmentOffHand.isEmpty()>
        this.setItemSlot(EquipmentSlot.OFFHAND, ${mappedMCItemToItemStackCode(data.equipmentOffHand, 1)});
        </#if>
        <#if !data.equipmentHelmet.isEmpty()>
        this.setItemSlot(EquipmentSlot.HEAD, ${mappedMCItemToItemStackCode(data.equipmentHelmet, 1)});
        </#if>
        <#if !data.equipmentBody.isEmpty()>
        this.setItemSlot(EquipmentSlot.CHEST, ${mappedMCItemToItemStackCode(data.equipmentBody, 1)});
        </#if>
        <#if !data.equipmentLeggings.isEmpty()>
        this.setItemSlot(EquipmentSlot.LEGS, ${mappedMCItemToItemStackCode(data.equipmentLeggings, 1)});
        </#if>
        <#if !data.equipmentBoots.isEmpty()>
        this.setItemSlot(EquipmentSlot.FEET, ${mappedMCItemToItemStackCode(data.equipmentBoots, 1)});
        </#if>

		<#if data.flyingMob>
		this.moveControl = new FlyingMoveControl(this, 10, true);
		<#elseif data.waterMob>
		this.setPathfindingMalus(PathType.WATER, 0);
		this.moveControl = new MoveControl(this) {
			@Override public void tick() {
			    if (${name}Entity.this.isInWater())
                    ${name}Entity.this.setDeltaMovement(${name}Entity.this.getDeltaMovement().add(0, 0.005, 0));

				if (this.operation == MoveControl.Operation.MOVE_TO && !${name}Entity.this.getNavigation().isDone()) {
					double dx = this.wantedX - ${name}Entity.this.getX();
					double dy = this.wantedY - ${name}Entity.this.getY();
					double dz = this.wantedZ - ${name}Entity.this.getZ();

					float f = (float) (Mth.atan2(dz, dx) * (double) (180 / Math.PI)) - 90;
					float f1 = (float) (this.speedModifier * ${name}Entity.this.getAttribute(Attributes.MOVEMENT_SPEED).getValue());

					${name}Entity.this.setYRot(this.rotlerp(${name}Entity.this.getYRot(), f, 10));
					${name}Entity.this.yBodyRot = ${name}Entity.this.getYRot();
					${name}Entity.this.yHeadRot = ${name}Entity.this.getYRot();

					if (${name}Entity.this.isInWater()) {
						${name}Entity.this.setSpeed((float) ${name}Entity.this.getAttribute(Attributes.MOVEMENT_SPEED).getValue());

						float f2 = - (float) (Mth.atan2(dy, (float) Math.sqrt(dx * dx + dz * dz)) * (180 / Math.PI));
						f2 = Mth.clamp(Mth.wrapDegrees(f2), -85, 85);
						${name}Entity.this.setXRot(this.rotlerp(${name}Entity.this.getXRot(), f2, 5));
						float f3 = Mth.cos(${name}Entity.this.getXRot() * (float) (Math.PI / 180.0));

						${name}Entity.this.setZza(f3 * f1);
						${name}Entity.this.setYya((float) (f1 * dy));
					} else {
						${name}Entity.this.setSpeed(f1 * 0.05F);
					}
				} else {
					${name}Entity.this.setSpeed(0);
					${name}Entity.this.setYya(0);
					${name}Entity.this.setZza(0);
				}
			}
		};
		</#if>

		<#if data.boundingBoxScale?? && data.boundingBoxScale.getFixedValue() != 1 && !hasProcedure(data.boundingBoxScale)>
		refreshDimensions();
		</#if>
	}

	<#if data.entityDataEntries?has_content>
	@Override protected void defineSynchedData(SynchedEntityData.Builder builder) {
		super.defineSynchedData(builder);
		<#list data.entityDataEntries as entry>
			builder.define(DATA_${entry.property().getName()}, ${entry.value()?is_string?then("\"" + JavaConventions.escapeStringForJava(entry.value()) + "\"", entry.value())});
		</#list>
	}
	</#if>

	<#if data.flyingMob>
	@Override protected PathNavigation createNavigation(Level world) {
		return new FlyingPathNavigation(this, world);
	}
	<#elseif data.waterMob>
	@Override protected PathNavigation createNavigation(Level world) {
		return new WaterBoundPathNavigation(this, world);
	}
	</#if>

	<#if data.aiBase == "Villager">
	@Override protected Component getTypeName() {
		return this.getType().getDescription();
	}
	</#if>

	<#if data.hasAI>
	@Override protected void registerGoals() {
		super.registerGoals();

		<#if aicode??>
			<#if aiblocks?seq_contains("doors_open") || aiblocks?seq_contains("doors_close")>
				this.getNavigation().getNodeEvaluator().setCanOpenDoors(true);
			</#if>

			${aicode}
		</#if>

        <#if data.ranged>
            this.goalSelector.addGoal(1, new RangedAttackGoal(this, 1.25, ${data.rangedAttackInterval}, ${data.rangedAttackRadius}f) {
				@Override public boolean canContinueToUse() {
					return this.canUse();
				}
			});
        </#if>
	}
	</#if>

	${extra_templates_code}

	<#if !data.doesDespawnWhenIdle>
	@Override public boolean removeWhenFarAway(double distanceToClosestPlayer) {
		return false;
	}
    </#if>

	<#if data.mobModelName == "Biped">
	@Override public Vec3 getPassengerRidingPosition(Entity entity) {
		return super.getPassengerRidingPosition(entity).add(0, -0.35F, 0);
	}
	<#elseif data.mobModelName == "Silverfish">
	@Override public Vec3 getPassengerRidingPosition(Entity entity) {
		return super.getPassengerRidingPosition(entity).add(0, 0.1F, 0);
	}
	</#if>

	<#if data.mountedYOffset != 0>
	@Override protected Vec3 getPassengerAttachmentPoint(Entity entity, EntityDimensions dimensions, float f) {
		return super.getPassengerAttachmentPoint(entity, dimensions, f).add(0, ${data.mountedYOffset}f, 0);
	}
	</#if>

	<#if !data.mobDrop.isEmpty()>
    protected void dropCustomDeathLoot(ServerLevel serverLevel, DamageSource source, boolean recentlyHitIn) {
        super.dropCustomDeathLoot(serverLevel, source, recentlyHitIn);
        this.spawnAtLocation(serverLevel, ${mappedMCItemToItemStackCode(data.mobDrop, 1)});
   	}
	</#if>

   	<#if data.livingSound?has_content && data.livingSound.getMappedValue()?has_content>
	@Override public SoundEvent getAmbientSound() {
		return BuiltInRegistries.SOUND_EVENT.getValue(ResourceLocation.parse("${data.livingSound}"));
	}
	</#if>

   	<#if data.stepSound?has_content && data.stepSound.getMappedValue()?has_content>
	@Override public void playStepSound(BlockPos pos, BlockState blockIn) {
		this.playSound(BuiltInRegistries.SOUND_EVENT.getValue(ResourceLocation.parse("${data.stepSound}")), 0.15f, 1);
	}
	</#if>

	<#if data.hurtSound?has_content && data.hurtSound.getMappedValue()?has_content>
	@Override public SoundEvent getHurtSound(DamageSource ds) {
		return BuiltInRegistries.SOUND_EVENT.getValue(ResourceLocation.parse("${data.hurtSound}"));
	}
	</#if>

	<#if data.deathSound?has_content && data.deathSound.getMappedValue()?has_content>
	@Override public SoundEvent getDeathSound() {
		return BuiltInRegistries.SOUND_EVENT.getValue(ResourceLocation.parse("${data.deathSound}"));
	}
	</#if>

	<#if data.mobBehaviourType == "Raider">
	@Override public SoundEvent getCelebrateSound() {
		<#if data.raidCelebrationSound?has_content && data.raidCelebrationSound.getMappedValue()?has_content>
		return BuiltInRegistries.SOUND_EVENT.getValue(ResourceLocation.parse("${data.raidCelebrationSound}"));
		<#else>
		return SoundEvents.EMPTY;
		</#if>
	}
	</#if>

	<#if hasProcedure(data.onStruckByLightning)>
	@Override public void thunderHit(ServerLevel serverWorld, LightningBolt lightningBolt) {
		super.thunderHit(serverWorld, lightningBolt);
		<@procedureCode data.onStruckByLightning, {
			"x": "this.getX()",
			"y": "this.getY()",
			"z": "this.getZ()",
			"entity": "this",
			"world": "this.level()"
		}/>
	}
    </#if>

	<#if hasProcedure(data.whenMobFalls) || data.flyingMob>
	@Override public boolean causeFallDamage(float l, float d, DamageSource source) {
		<#if hasProcedure(data.whenMobFalls)>
			<@procedureCode data.whenMobFalls, {
				"x": "this.getX()",
				"y": "this.getY()",
				"z": "this.getZ()",
				"entity": "this",
				"world": "this.level()",
				"damagesource": "source"
			}/>
		</#if>

		<#if data.flyingMob>
			return false;
		<#else>
			return super.causeFallDamage(l, d, source);
		</#if>
	}
    </#if>

	<#if hasProcedure(data.whenMobIsHurt) || data.immuneToFire || data.immuneToArrows || data.immuneToFallDamage
		|| data.immuneToCactus || data.immuneToDrowning || data.immuneToLightning || data.immuneToPotions
		|| data.immuneToPlayer || data.immuneToExplosion || data.immuneToTrident || data.immuneToAnvil
		|| data.immuneToDragonBreath || data.immuneToWither>
	@Override public boolean hurtServer(ServerLevel level, DamageSource damagesource, float amount) {
		<#if hasProcedure(data.whenMobIsHurt)>
			double x = this.getX();
			double y = this.getY();
			double z = this.getZ();
			Level world = this.level();
			Entity entity = this;
			Entity sourceentity = damagesource.getEntity();
			Entity immediatesourceentity = damagesource.getDirectEntity();
			<#if hasReturnValueOf(data.whenMobIsHurt, "logic")>
			if (<@procedureOBJToConditionCode data.whenMobIsHurt false true/>)
				return false;
			<#else>
				<@procedureOBJToCode data.whenMobIsHurt/>
			</#if>
		</#if>
		<#if data.immuneToFire>
			if (damagesource.is(DamageTypes.IN_FIRE))
				return false;
		</#if>
		<#if data.immuneToArrows>
			if (damagesource.getDirectEntity() instanceof AbstractArrow)
				return false;
		</#if>
		<#if data.immuneToPlayer>
			if (damagesource.getDirectEntity() instanceof Player)
				return false;
		</#if>
		<#if data.immuneToPotions>
			if (damagesource.getDirectEntity() instanceof ThrownPotion || damagesource.getDirectEntity() instanceof AreaEffectCloud
					|| damagesource.typeHolder().is(NeoForgeMod.POISON_DAMAGE))
				return false;
		</#if>
		<#if data.immuneToFallDamage>
			if (damagesource.is(DamageTypes.FALL))
				return false;
		</#if>
		<#if data.immuneToCactus>
			if (damagesource.is(DamageTypes.CACTUS))
				return false;
		</#if>
		<#if data.immuneToDrowning>
			if (damagesource.is(DamageTypes.DROWN))
				return false;
		</#if>
		<#if data.immuneToLightning>
			if (damagesource.is(DamageTypes.LIGHTNING_BOLT))
				return false;
		</#if>
		<#if data.immuneToExplosion>
			if (damagesource.is(DamageTypes.EXPLOSION) || damagesource.is(DamageTypes.PLAYER_EXPLOSION))
				return false;
		</#if>
		<#if data.immuneToTrident>
			if (damagesource.is(DamageTypes.TRIDENT))
				return false;
		</#if>
		<#if data.immuneToAnvil>
			if (damagesource.is(DamageTypes.FALLING_ANVIL))
				return false;
		</#if>
		<#if data.immuneToDragonBreath>
			if (damagesource.is(DamageTypes.DRAGON_BREATH))
				return false;
		</#if>
		<#if data.immuneToWither>
			if (damagesource.is(DamageTypes.WITHER) || damagesource.is(DamageTypes.WITHER_SKULL))
				return false;
		</#if>
		return super.hurtServer(level, damagesource, amount);
	}
    </#if>

	<#if data.immuneToExplosion>
	@Override public boolean ignoreExplosion(Explosion explosion) {
		return true;
	}
	</#if>

	<#if data.immuneToFire>
	@Override public boolean fireImmune() {
		return true;
	}
	</#if>

	<#if hasProcedure(data.whenMobDies)>
	@Override public void die(DamageSource source) {
		super.die(source);
		<@procedureCode data.whenMobDies, {
			"x": "this.getX()",
			"y": "this.getY()",
			"z": "this.getZ()",
			"sourceentity": "source.getEntity()",
			"immediatesourceentity": "source.getDirectEntity()",
			"entity": "this",
			"world": "this.level()",
			"damagesource": "source"
		}/>
	}
    </#if>

	<#if hasProcedure(data.onInitialSpawn)>
	@Override public SpawnGroupData finalizeSpawn(ServerLevelAccessor world, DifficultyInstance difficulty, EntitySpawnReason reason, @Nullable SpawnGroupData livingdata) {
		SpawnGroupData retval = super.finalizeSpawn(world, difficulty, reason, livingdata);
		<@procedureCode data.onInitialSpawn, {
			"x": "this.getX()",
			"y": "this.getY()",
			"z": "this.getZ()",
			"world": "world",
			"entity": "this"
		}/>
		return retval;
	}
    </#if>

	<#if data.guiBoundTo?has_content>
	private final ItemStackHandler inventory = new ItemStackHandler(${data.inventorySize})
	<#if data.inventoryStackSize != 99>
	{
		@Override public int getSlotLimit(int slot) {
			return ${data.inventoryStackSize};
		}
	}
	</#if>;

	private final CombinedInvWrapper combined = new CombinedInvWrapper(inventory, new EntityHandsInvWrapper(this), new EntityArmorInvWrapper(this));

	public CombinedInvWrapper getCombinedInventory() {
		return combined;
	}

   	@Override protected void dropEquipment(ServerLevel serverLevel) {
		super.dropEquipment(serverLevel);
		for (int i = 0; i < inventory.getSlots(); ++i) {
			ItemStack itemstack = inventory.getStackInSlot(i);
			if (!itemstack.isEmpty() && !EnchantmentHelper.has(itemstack, EnchantmentEffectComponents.PREVENT_EQUIPMENT_DROP)) {
				this.spawnAtLocation(serverLevel, itemstack);
			}
		}
	}
	</#if>

	<#if data.entityDataEntries?has_content || data.guiBoundTo?has_content || data.sensitiveToVibration>
	@Override public void addAdditionalSaveData(CompoundTag compound) {
		super.addAdditionalSaveData(compound);
		<#list data.entityDataEntries as entry>
			<#if entry.value().getClass().getSimpleName() == "Integer">
			compound.putInt("Data${entry.property().getName()}", this.entityData.get(DATA_${entry.property().getName()}));
			<#elseif entry.value().getClass().getSimpleName() == "Boolean">
			compound.putBoolean("Data${entry.property().getName()}", this.entityData.get(DATA_${entry.property().getName()}));
			<#elseif entry.value().getClass().getSimpleName() == "String">
			compound.putString("Data${entry.property().getName()}", this.entityData.get(DATA_${entry.property().getName()}));
			</#if>
		</#list>
		<#if data.guiBoundTo?has_content>
		compound.put("InventoryCustom", inventory.serializeNBT(this.registryAccess()));
		</#if>
		<#if data.sensitiveToVibration>
		VibrationSystem.Data.CODEC.encodeStart(this.registryAccess().createSerializationContext(NbtOps.INSTANCE), this.vibrationData)
			.resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to encode vibration listener for ${name}: '{}'", e))
			.ifPresent(listener -> compound.put("listener", listener));
		</#if>
	}

	@Override public void readAdditionalSaveData(CompoundTag compound) {
		super.readAdditionalSaveData(compound);
		<#list data.entityDataEntries as entry>
			if (compound.contains("Data${entry.property().getName()}"))
				<#if entry.value().getClass().getSimpleName() == "Integer">
				this.entityData.set(DATA_${entry.property().getName()}, compound.getInt("Data${entry.property().getName()}"));
				<#elseif entry.value().getClass().getSimpleName() == "Boolean">
				this.entityData.set(DATA_${entry.property().getName()}, compound.getBoolean("Data${entry.property().getName()}"));
				<#elseif entry.value().getClass().getSimpleName() == "String">
				this.entityData.set(DATA_${entry.property().getName()}, compound.getString("Data${entry.property().getName()}"));
				</#if>
		</#list>
		<#if data.guiBoundTo?has_content>
		if (compound.get("InventoryCustom") instanceof CompoundTag inventoryTag)
			inventory.deserializeNBT(this.registryAccess(), inventoryTag);
		</#if>
		<#if data.sensitiveToVibration>
		if (compound.contains("listener", Tag.TAG_COMPOUND)) {
			VibrationSystem.Data.CODEC.parse(this.registryAccess().createSerializationContext(NbtOps.INSTANCE), compound.getCompound("listener"))
				.resultOrPartial(e -> ${JavaModName}.LOGGER.error("Failed to parse vibration listener for ${name}: '{}'", e))
				.ifPresent(data -> this.vibrationData = data);
		}
		</#if>
	}
	</#if>

	<#if data.sensitiveToVibration>
	@Override public void updateDynamicGameEventListener(BiConsumer<DynamicGameEventListener<?>, ServerLevel> listenerConsumer) {
		if (this.level() instanceof ServerLevel serverLevel) {
			listenerConsumer.accept(this.dynamicGameEventListener, serverLevel);
		}
	}

	@Override public VibrationSystem.Data getVibrationData() {
		return this.vibrationData;
	}

	@Override public VibrationSystem.User getVibrationUser() {
		return this.vibrationUser;
	}
	</#if>

	<#if hasProcedure(data.onRightClickedOn) || data.ridable || (data.tameable && data.breedable) || data.guiBoundTo?has_content>
	@Override public InteractionResult mobInteract(Player sourceentity, InteractionHand hand) {
		ItemStack itemstack = sourceentity.getItemInHand(hand);
		InteractionResult retval = InteractionResult.SUCCESS;

		<#if data.guiBoundTo?has_content>
			<#if data.ridable>
				if (sourceentity.isSecondaryUseActive()) {
			</#if>
				if (sourceentity instanceof ServerPlayer serverPlayer) {
					serverPlayer.openMenu(new MenuProvider() {

						@Override public Component getDisplayName() {
							return Component.literal("${data.mobName}");
						}

						@Override public AbstractContainerMenu createMenu(int id, Inventory inventory, Player player) {
							FriendlyByteBuf packetBuffer = new FriendlyByteBuf(Unpooled.buffer());
							packetBuffer.writeBlockPos(sourceentity.blockPosition());
							packetBuffer.writeByte(0);
							packetBuffer.writeVarInt(${name}Entity.this.getId());
							return new ${data.guiBoundTo}Menu(id, inventory, packetBuffer);
						}

					}, buf -> {
						buf.writeBlockPos(sourceentity.blockPosition());
						buf.writeByte(0);
						buf.writeVarInt(this.getId());
					});
				}
			<#if data.ridable>
					return InteractionResult.SUCCESS;
				}
			</#if>
		</#if>

		<#if (data.tameable && data.breedable)>
			Item item = itemstack.getItem();
			if (itemstack.getItem() instanceof SpawnEggItem) {
				retval = super.mobInteract(sourceentity, hand);
			} else if (this.level().isClientSide()) {
				retval = (this.isTame() && this.isOwnedBy(sourceentity) || this.isFood(itemstack))
						? InteractionResult.SUCCESS : InteractionResult.PASS;
			} else {
				if (this.isTame()) {
					if (this.isOwnedBy(sourceentity)) {
						if (this.isFood(itemstack) && this.getHealth() < this.getMaxHealth()) {
							this.usePlayerItem(sourceentity, hand, itemstack);
							FoodProperties foodproperties = itemstack.get(DataComponents.FOOD);
							float nutrition = foodproperties != null ? (float) foodproperties.nutrition() : 1;
							this.heal(nutrition);
							retval = InteractionResult.SUCCESS;
						} else if (this.isFood(itemstack) && this.getHealth() < this.getMaxHealth()) {
							this.usePlayerItem(sourceentity, hand, itemstack);
							this.heal(4);
							retval = InteractionResult.SUCCESS;
						} else {
							retval = super.mobInteract(sourceentity, hand);
						}
					}
				} else if (this.isFood(itemstack)) {
					this.usePlayerItem(sourceentity, hand, itemstack);
					if (this.random.nextInt(3) == 0 && !EventHooks.onAnimalTame(this, sourceentity)) {
						this.tame(sourceentity);
						this.level().broadcastEntityEvent(this, (byte) 7);
					} else {
						this.level().broadcastEntityEvent(this, (byte) 6);
					}

					this.setPersistenceRequired();
					retval = InteractionResult.SUCCESS;
				} else {
					retval = super.mobInteract(sourceentity, hand);
					if (retval == InteractionResult.SUCCESS || retval == InteractionResult.CONSUME)
						this.setPersistenceRequired();
				}
			}
		<#else>
			super.mobInteract(sourceentity, hand);
		</#if>

		<#if data.ridable>
		sourceentity.startRiding(this);
	    </#if>

		<#if hasProcedure(data.onRightClickedOn)>
			double x = this.getX();
			double y = this.getY();
			double z = this.getZ();
			Entity entity = this;
			Level world = this.level();
			<#if hasReturnValueOf(data.onRightClickedOn, "actionresulttype")>
				return <@procedureOBJToInteractionResultCode data.onRightClickedOn/>;
			<#else>
				<@procedureOBJToCode data.onRightClickedOn/>
				return retval;
			</#if>
		<#else>
			return retval;
		</#if>
	}
    </#if>

	<#if hasProcedure(data.whenThisMobKillsAnother)>
	@Override public void awardKillScore(Entity entity, DamageSource damageSource) {
		super.awardKillScore(entity, damageSource);
		<@procedureCode data.whenThisMobKillsAnother, {
			"x": "this.getX()",
			"y": "this.getY()",
			"z": "this.getZ()",
			"entity": "entity",
			"sourceentity": "this",
			"immediatesourceentity": "damageSource.getDirectEntity()",
			"world": "this.level()",
			"damagesource": "damageSource"
		}/>
	}
    </#if>

	<#if hasPlayableAnimations || data.sensitiveToVibration>
	@Override public void tick() {
		super.tick();

		<#if data.sensitiveToVibration>
		if (this.level() instanceof ServerLevel serverLevel) {
			VibrationSystem.Ticker.tick(serverLevel, this.vibrationData, this.vibrationUser);
		}
		</#if>

		<#if hasPlayableAnimations>
		if (this.level().isClientSide()) {
			<#list data.animations as animation>
				<#if !animation.walking>
					<#if hasProcedure(animation.condition)>
					this.animationState${animation?index}.animateWhen(<@procedureCode animation.condition, {
						"x": "this.getX()",
						"y": "this.getY()",
						"z": "this.getZ()",
						"entity": "this",
						"world": "this.level()"
					}, false/>, this.tickCount);
					<#else>
					this.animationState${animation?index}.animateWhen(true, this.tickCount);
					</#if>
				</#if>
			</#list>
		}
		</#if>
	}
	</#if>

	<#if hasProcedure(data.onMobTickUpdate) || hasProcedure(data.boundingBoxScale)>
	@Override public void baseTick() {
		super.baseTick();
		<#if hasProcedure(data.onMobTickUpdate)>
			<@procedureCode data.onMobTickUpdate, {
				"x": "this.getX()",
				"y": "this.getY()",
				"z": "this.getZ()",
				"entity": "this",
				"world": "this.level()"
			}/>
		</#if>
		<#if hasProcedure(data.boundingBoxScale)>
			this.refreshDimensions();
		</#if>
	}
    </#if>

	<#if hasProcedure(data.onPlayerCollidesWith)>
	@Override public void playerTouch(Player sourceentity) {
		super.playerTouch(sourceentity);
		<@procedureCode data.onPlayerCollidesWith, {
			"x": "this.getX()",
			"y": "this.getY()",
			"z": "this.getZ()",
			"entity": "this",
			"sourceentity": "sourceentity",
			"world": "this.level()"
		}/>
	}
    </#if>

    <#if data.ranged>
	    @Override public void performRangedAttack(LivingEntity target, float flval) {
			<#if data.rangedItemType == "Default item">
				<#if !data.rangedAttackItem.isEmpty()>
				${name}EntityProjectile entityarrow = new ${name}EntityProjectile(${JavaModName}Entities.${REGISTRYNAME}_PROJECTILE.get(), this, this.level());
				<#else>
				Arrow entityarrow = new Arrow(this.level(), this, new ItemStack(Items.ARROW), null);
				</#if>
				double d0 = target.getY() + target.getEyeHeight() - 1.1;
				double d1 = target.getX() - this.getX();
				double d3 = target.getZ() - this.getZ();
				entityarrow.shoot(d1, d0 - entityarrow.getY() + Math.sqrt(d1 * d1 + d3 * d3) * 0.2F, d3, 1.6F, 12.0F);
				this.level().addFreshEntity(entityarrow);
			<#else>
				${data.rangedItemType}Entity.shoot(this, target);
			</#if>
		}
    </#if>

	<#if data.breedable>
        @Override public AgeableMob getBreedOffspring(ServerLevel serverWorld, AgeableMob ageable) {
			${name}Entity retval = ${JavaModName}Entities.${REGISTRYNAME}.get().create(serverWorld, EntitySpawnReason.BREEDING);
			retval.finalizeSpawn(serverWorld, serverWorld.getCurrentDifficultyAt(retval.blockPosition()), EntitySpawnReason.BREEDING, null);
			return retval;
		}

		@Override public boolean isFood(ItemStack stack) {
			return ${mappedMCItemsToIngredient(data.breedTriggerItems)}.test(stack);
		}
    </#if>

	<#if data.waterMob>
	@Override public boolean checkSpawnObstruction(LevelReader world) {
		return world.isUnobstructed(this);
	}
	</#if>

	<#if data.breatheUnderwater?? && (hasProcedure(data.breatheUnderwater) || data.breatheUnderwater.getFixedValue())>
	@Override public boolean canDrownInFluidType(FluidType type) {
		double x = this.getX();
		double y = this.getY();
		double z = this.getZ();
		Level world = this.level();
		Entity entity = this;
		return <@procedureOBJToConditionCode data.breatheUnderwater false true/>;
	}
	</#if>

	<#if data.pushedByFluids?? && (hasProcedure(data.pushedByFluids) || !data.pushedByFluids.getFixedValue())>
	@Override public boolean isPushedByFluid() {
		double x = this.getX();
		double y = this.getY();
		double z = this.getZ();
		Level world = this.level();
		Entity entity = this;
		return <@procedureOBJToConditionCode data.pushedByFluids false false/>;
	}
	</#if>

	<#if data.disableCollisions>
	@Override public boolean isPushable() {
		return false;
	}

   	@Override protected void doPush(Entity entityIn) {
   	}

   	@Override protected void pushEntities() {
   	}
	</#if>

	<#if data.solidBoundingBox?? && (hasProcedure(data.solidBoundingBox) || data.solidBoundingBox.getFixedValue())>
	@Override
	public boolean canCollideWith(Entity entity) {
		return true;
	}

	@Override
	public boolean canBeCollidedWith() {
		<#if hasProcedure(data.solidBoundingBox)>
		Entity entity = this;
		Level world = entity.level();
		double x = entity.getX();
		double y = entity.getY();
		double z = entity.getZ();
		</#if>
		return <@procedureOBJToConditionCode data.solidBoundingBox true false/>;
	}
	</#if>

	<#if data.isBoss>
	@Override public void startSeenByPlayer(ServerPlayer player) {
		super.startSeenByPlayer(player);
		this.bossInfo.addPlayer(player);
	}

	@Override public void stopSeenByPlayer(ServerPlayer player) {
		super.stopSeenByPlayer(player);
		this.bossInfo.removePlayer(player);
	}

	@Override public void customServerAiStep(ServerLevel serverLevel) {
		super.customServerAiStep(serverLevel);
		this.bossInfo.setProgress(this.getHealth() / this.getMaxHealth());
	}
	</#if>

    <#if data.ridable && (data.canControlForward || data.canControlStrafe)>
        @Override public void travel(Vec3 dir) {
        	<#if data.canControlForward || data.canControlStrafe>
			Entity entity = this.getPassengers().isEmpty() ? null : (Entity) this.getPassengers().get(0);
			if (this.isVehicle()) {
				this.setYRot(entity.getYRot());
				this.yRotO = this.getYRot();
				this.setXRot(entity.getXRot() * 0.5F);
				this.setRot(this.getYRot(), this.getXRot());
				this.yBodyRot = entity.getYRot();
				this.yHeadRot = entity.getYRot();

				if (entity instanceof ServerPlayer passenger) {
					this.setSpeed((float) this.getAttributeValue(Attributes.MOVEMENT_SPEED));

					<#if data.canControlForward>
						float forward = passenger.getLastClientInput().forward() == passenger.getLastClientInput().backward() ? 0 : (passenger.getLastClientInput().forward() ? 1 : -1);
					<#else>
						float forward = 0;
					</#if>

					<#if data.canControlStrafe>
						float strafe = passenger.getLastClientInput().left() == passenger.getLastClientInput().right() ? 0 : (passenger.getLastClientInput().left() ? 1 : -1);
					<#else>
						float strafe = 0;
					</#if>

					super.travel(new Vec3(strafe, 0, forward));
				}

				double d1 = this.getX() - this.xo;
				double d0 = this.getZ() - this.zo;
				float f1 = (float) Math.sqrt(d1 * d1 + d0 * d0) * 4;
				if (f1 > 1.0F) f1 = 1.0F;
				this.walkAnimation.setSpeed(this.walkAnimation.speed() + (f1 - this.walkAnimation.speed()) * 0.4F);
				this.walkAnimation.position(this.walkAnimation.position() + this.walkAnimation.speed());
				this.calculateEntityAnimation(true);
				return;
			}
			</#if>

			super.travel(dir);
		}
    </#if>

	<#if hasProcedure(data.boundingBoxScale) || (data.boundingBoxScale?? && data.boundingBoxScale.getFixedValue() != 1)>
	@Override public EntityDimensions getDefaultDimensions(Pose pose) {
		<#if hasProcedure(data.boundingBoxScale)>
			Entity entity = this;
			Level world = this.level();
			double x = this.getX();
			double y = this.getY();
			double z = this.getZ();
			return super.getDefaultDimensions(pose).scale((float) <@procedureOBJToNumberCode data.boundingBoxScale/>);
		<#else>
			return super.getDefaultDimensions(pose).scale(${data.boundingBoxScale.getFixedValue()}f);
		</#if>
	}
	</#if>

	<#if data.flyingMob>
	@Override protected void checkFallDamage(double y, boolean onGroundIn, BlockState state, BlockPos pos) {
   	}

   	@Override public void setNoGravity(boolean ignored) {
		super.setNoGravity(true);
	}
    </#if>

    <#if data.flyingMob>
    public void aiStep() {
		super.aiStep();

		this.setNoGravity(true);
	}
    </#if>

	public static void init(RegisterSpawnPlacementsEvent event) {
		<#if data.spawnThisMob>
			<#if data.mobSpawningType == "creature">
			event.register(${JavaModName}Entities.${REGISTRYNAME}.get(),
					SpawnPlacementTypes.ON_GROUND, Heightmap.Types.MOTION_BLOCKING_NO_LEAVES,
				<#if hasProcedure(data.spawningCondition)>
					(entityType, world, reason, pos, random) -> {
						int x = pos.getX();
						int y = pos.getY();
						int z = pos.getZ();
						return <@procedureOBJToConditionCode data.spawningCondition/>;
					}
				<#else>
					(entityType, world, reason, pos, random) ->
							(world.getBlockState(pos.below()).is(BlockTags.ANIMALS_SPAWNABLE_ON) &&
							world.getRawBrightness(pos, 0) > 8)
				</#if>,
				RegisterSpawnPlacementsEvent.Operation.REPLACE
			);
			<#elseif data.mobSpawningType == "ambient" || data.mobSpawningType == "misc">
			event.register(${JavaModName}Entities.${REGISTRYNAME}.get(),
					SpawnPlacementTypes.NO_RESTRICTIONS, Heightmap.Types.MOTION_BLOCKING_NO_LEAVES,
					<#if hasProcedure(data.spawningCondition)>
					(entityType, world, reason, pos, random) -> {
						int x = pos.getX();
						int y = pos.getY();
						int z = pos.getZ();
						return <@procedureOBJToConditionCode data.spawningCondition/>;
					}
					<#else>
					Mob::checkMobSpawnRules
					</#if>,
					RegisterSpawnPlacementsEvent.Operation.REPLACE
			);
			<#elseif data.mobSpawningType == "waterCreature" || data.mobSpawningType == "waterAmbient">
			event.register(${JavaModName}Entities.${REGISTRYNAME}.get(),
					SpawnPlacementTypes.IN_WATER, Heightmap.Types.MOTION_BLOCKING_NO_LEAVES,
					<#if hasProcedure(data.spawningCondition)>
					(entityType, world, reason, pos, random) -> {
						int x = pos.getX();
						int y = pos.getY();
						int z = pos.getZ();
						return <@procedureOBJToConditionCode data.spawningCondition/>;
					}
					<#else>
					(entityType, world, reason, pos, random) ->
							(world.getBlockState(pos).is(Blocks.WATER) &&
							world.getBlockState(pos.above()).is(Blocks.WATER))
					</#if>,
					RegisterSpawnPlacementsEvent.Operation.REPLACE
			);
			<#elseif data.mobSpawningType == "undergroundWaterCreature">
			event.register(${JavaModName}Entities.${REGISTRYNAME}.get(),
					SpawnPlacementTypes.IN_WATER, Heightmap.Types.MOTION_BLOCKING_NO_LEAVES,
					<#if hasProcedure(data.spawningCondition)>
					(entityType, world, reason, pos, random) -> {
						int x = pos.getX();
						int y = pos.getY();
						int z = pos.getZ();
						return <@procedureOBJToConditionCode data.spawningCondition/>;
					}
					<#else>
					(entityType, world, reason, pos, random) ->
							(world.getFluidState(pos.below()).is(FluidTags.WATER) &&
							world.getBlockState(pos.above()).is(Blocks.WATER) &&
							pos.getY() >= (world.getSeaLevel() - 13) &&
							pos.getY() <= world.getSeaLevel())
					</#if>,
					RegisterSpawnPlacementsEvent.Operation.REPLACE
			);
			<#else>
			event.register(${JavaModName}Entities.${REGISTRYNAME}.get(),
					SpawnPlacementTypes.ON_GROUND, Heightmap.Types.MOTION_BLOCKING_NO_LEAVES,
					<#if hasProcedure(data.spawningCondition)>
					(entityType, world, reason, pos, random) -> {
						int x = pos.getX();
						int y = pos.getY();
						int z = pos.getZ();
						return <@procedureOBJToConditionCode data.spawningCondition/>;
					}
					<#else>
						(entityType, world, reason, pos, random) ->
								(world.getDifficulty() != Difficulty.PEACEFUL &&
								Monster.isDarkEnoughToSpawn(world, pos, random) &&
								Mob.checkMobSpawnRules(entityType, world, reason, pos, random))
					</#if>,
					RegisterSpawnPlacementsEvent.Operation.REPLACE
			);
			</#if>
		</#if>
	}

	<#if data.mobBehaviourType == "Raider">
	@Override public void applyRaidBuffs(ServerLevel serverLevel, int num, boolean logic) {}
	</#if>

	public static AttributeSupplier.Builder createAttributes() {
		AttributeSupplier.Builder builder = Mob.createMobAttributes();
		builder = builder.add(Attributes.MOVEMENT_SPEED, ${data.movementSpeed});
		builder = builder.add(Attributes.MAX_HEALTH, ${data.health});
		builder = builder.add(Attributes.ARMOR, ${data.armorBaseValue});
		builder = builder.add(Attributes.ATTACK_DAMAGE, ${data.attackStrength});
		builder = builder.add(Attributes.FOLLOW_RANGE, ${data.followRange});

		builder = builder.add(Attributes.STEP_HEIGHT, ${data.stepHeight});

		<#if (data.knockbackResistance > 0)>
		builder = builder.add(Attributes.KNOCKBACK_RESISTANCE, ${data.knockbackResistance});
		</#if>

		<#if (data.attackKnockback > 0)>
		builder = builder.add(Attributes.ATTACK_KNOCKBACK, ${data.attackKnockback});
		</#if>

		<#if data.flyingMob>
		builder = builder.add(Attributes.FLYING_SPEED, ${data.movementSpeed});
		</#if>

		<#if data.waterMob>
		builder = builder.add(NeoForgeMod.SWIM_SPEED, ${data.movementSpeed});
		</#if>

		<#if data.aiBase == "Zombie">
		builder = builder.add(Attributes.SPAWN_REINFORCEMENTS_CHANCE);
		</#if>

		<#if aiblocks?seq_contains("follow_item_in_hands")>
		builder = builder.add(Attributes.TEMPT_RANGE, 10);
		</#if>

		return builder;
	}

	<#if data.sensitiveToVibration>
	private class VibrationUser implements VibrationSystem.User {

		private final ${name}Entity entity = ${name}Entity.this;
		private final PositionSource positionSource = new EntityPositionSource(this.entity, this.entity.getEyeHeight());

		@Override public PositionSource getPositionSource() {
			return this.positionSource;
		}

		<#if data.vibrationalEvents?has_content>
		@Override public TagKey<GameEvent> getListenableEvents() {
			return TagKey.create(Registries.GAME_EVENT, ResourceLocation.withDefaultNamespace("${data.getModElement().getRegistryName()}_can_listen"));
		}
		</#if>

		@Override public int getListenerRadius() {
			<#if hasProcedure(data.vibrationSensitivityRadius)>
				Level world = entity.level();
				double x = entity.getX();
				double y = entity.getY();
				double z = entity.getZ();
				return (int) <@procedureOBJToNumberCode data.vibrationSensitivityRadius/>;
			<#else>
				return ${data.vibrationSensitivityRadius.getFixedValue()};
			</#if>
		}

		@Override public boolean canReceiveVibration(ServerLevel world, BlockPos vibrationPos, Holder<GameEvent> holder, GameEvent.Context context) {
			<#if hasProcedure(data.canReceiveVibrationCondition)>
				return <@procedureCode data.canReceiveVibrationCondition {
					"x": "entity.getX()",
					"y": "entity.getY()",
					"z": "entity.getZ()",
					"vibrationX": "vibrationPos.getX()",
					"vibrationY": "vibrationPos.getY()",
					"vibrationZ": "vibrationPos.getZ()",
					"world": "world",
					"entity": "entity",
					"sourceentity": "context.sourceEntity()"
				}/>
			<#else>
				return true;
			</#if>
		}

		@Override public void onReceiveVibration(ServerLevel world, BlockPos vibrationPos, Holder<GameEvent> holder, @Nullable Entity vibrationSource, @Nullable Entity projectileShooter, float distance) {
			<#if hasProcedure(data.onReceivedVibration)>
				<@procedureCode data.onReceivedVibration {
					"x": "entity.getX()",
					"y": "entity.getY()",
					"z": "entity.getZ()",
					"vibrationX": "vibrationPos.getX()",
					"vibrationY": "vibrationPos.getY()",
					"vibrationZ": "vibrationPos.getZ()",
					"world": "world",
					"entity": "entity",
					"sourceentity": "vibrationSource",
					"immediatesourceentity": "projectileShooter"
				}/>
			</#if>
		}
	}
	</#if>

}
<#-- @formatter:off -->
