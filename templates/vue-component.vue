<script setup lang="ts">
import { computed, ref } from 'vue'

const COMPONENT_STATES = {
  IDLE: 'idle',
  LOADING: 'loading',
} as const

type ComponentState = (typeof COMPONENT_STATES)[keyof typeof COMPONENT_STATES]

interface Props {
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  label: '操作',
})

const emit = defineEmits<{
  action: []
}>()

const currentState = ref<ComponentState>(COMPONENT_STATES.IDLE)

const isLoading = computed(() => currentState.value === COMPONENT_STATES.LOADING)

function handleAction(): void {
  currentState.value = COMPONENT_STATES.LOADING
  emit('action')
  currentState.value = COMPONENT_STATES.IDLE
}
</script>

<template>
  <section aria-label="ComponentName">
    <button
      type="button"
      :disabled="isLoading"
      @click="handleAction"
    >
      {{ props.label }}
    </button>
  </section>
</template>

<style scoped>
button:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}
</style>
