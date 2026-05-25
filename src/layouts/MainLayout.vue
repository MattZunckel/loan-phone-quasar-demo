<template>
  <q-layout view="hHh lpR fFf" class="application-shell">
    <q-header elevated class="bg-white text-dark">
      <q-toolbar class="q-px-md">
        <q-avatar color="primary" text-color="dark" icon="phone_iphone" />
        <q-toolbar-title class="text-weight-bold">Phone Finance Application</q-toolbar-title>
      </q-toolbar>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>
